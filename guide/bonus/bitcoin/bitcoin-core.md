---
layout: default
title: Bitcoin Core
parent: + Bitcoin
grand_parent: Bonus Section
nav_exclude: true
has_toc: false
---

<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Bonus guide: Bitcoin Core
{:.no_toc}

{: .text-center}
![bitcoin knots logo](../../../images/bonus-bitcoin-bitcoin-core_logo.png){: width="20%"}

We install [Bitcoin Core](https://bitcoincore.org/){:target="_blank"}, the reference client implementation of the Bitcoin network. If you prefer to use [Bitcoin Knots](https://bitcoinknots.org/){:target="_blank"}, please refer to this [guide](../../mobybolt/bitcoin/bitcoin-client.md).

{:.important}
You can't install Bitcoin Knots and Bitcoin Core together. If you have already installed Bitcoin Knots, please [uninstall](../../mobybolt/bitcoin/bitcoin-client#uninstall) it before to proceed (you can safely keep volume data).

---

To follow this section, log in to your node as `satoshi` user via Secure Shell (SSH) and access the project's home:

```sh
$ cd $HOME/apps/mobybolt
```

---

## Table of contents
{: .no_toc .text-delta}

1. TOC
{:toc}

---

## Prepare

Let's create the directory structure for Bitcoin Core:

```sh
$ mkdir -p bitcoin-core
```

### Prepare the environment

Edit the `.env` file and append the following content to the end:

```sh
$ nano .env
```

```ini
# bitcoin
BITCOIN_VERSION=v28.1
BITCOIN_ADDRESS=172.16.21.10
BITCOIN_GUID=1100
```

In this file:
1. we define the `BITCOIN_VERSION` (check the latest available version [here](https://github.com/bitcoin/bitcoin/releases){:target="_blank"});
2. we define a static address for the container;
3. we define the `guid` (group and user id) of the bitcoin user.

### Prepare the Dockerfile

Create the [Dockerfile](https://docs.docker.com/reference/dockerfile/){:target="_blank"} and populate it with the following content:

```sh
$ nano bitcoin-core/Dockerfile
```

```Dockerfile
# base image
FROM debian:stable-slim AS base

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
        # build requirements
        automake \
        autotools-dev \
        bsdmainutils \
        build-essential \
        ccache \
        curl \
        git \
        libtool \
        pkg-config \
        python3 \
        # dependencies
        libboost-dev \
        libevent-dev \
        libsqlite3-dev \
        libzmq3-dev && \    
    rm -rf /var/lib/apt/lists/*


# builder image
FROM base AS builder

ARG BITCOIN_VERSION

ENV BITCOIN_URL="https://github.com/bitcoin/bitcoin.git" \
    BITCOIN_KEYS_URL="https://api.github.com/repositories/355107265/contents/builder-keys"

RUN set -eux && \
    # clone repository
    git clone --branch $BITCOIN_VERSION $BITCOIN_URL  && \
    # imports automatically all signatures from the Bitcoin Core release attestations (Guix) repository
    curl -s \
        $BITCOIN_KEYS_URL |\
        grep download_url |\
        grep -oE "https://[a-zA-Z0-9./-]+" |\
        while read url; do \
            curl -s "$url" |\
            gpg --import; \
        done

WORKDIR bitcoin

RUN set -xe && \
    # verify signature
    git verify-tag $BITCOIN_VERSION && \
    # build bdb 4.8
    make -C depends NO_BOOST=1 NO_LIBEVENT=1 NO_QT=1 NO_SQLITE=1 NO_NATPMP=1 NO_UPNP=1 NO_ZMQ=1 NO_USDT=1 && \
    # configure
    ./autogen.sh && \
    export BDB_PREFIX="$PWD/depends/$( ls depends | grep linux-gnu )" && \
    ./configure \
        BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BDB_PREFIX}/include" \
        --disable-bench \
        --disable-gui-tests \
        --disable-maintainer-mode \
        --disable-man \
        --disable-tests \
        --with-daemon=yes \
        --with-gui=no \
        --with-qrencode=no \
        --with-utils=yes && \
    # build
    make -j$(nproc) && \
    # install
    make install


# base image
FROM debian:stable-slim

# copy bitcoin binaries and libraries
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
        libevent-dev \
        libsqlite3-dev \
        libzmq3-dev && \
    rm -rf /var/lib/apt/lists/*

# default uid for bitcoin user
ARG BITCOIN_GUID=1100

# default gid for tor group
ARG TOR_GUID=102

RUN set -eux && \
    # setup bitcoin user
    adduser --disabled-password --comment "" --uid $BITCOIN_GUID bitcoin && \
    addgroup --gid $TOR_GUID tor && \
    adduser bitcoin tor && \
    # setup dirs and permissions
    mkdir -m 0750 /home/bitcoin/.bitcoin && \
    mkdir -m 0700 /run/bitcoind && \
    chown bitcoin:bitcoin /home/bitcoin/.bitcoin /run/bitcoind

# switch user
USER bitcoin
WORKDIR /home/bitcoin

# setup entrypoint
ENTRYPOINT ["bitcoind"]
CMD ["-pid=/run/bitcoind/bitcoind.pid"]
```

In this file:
1. we define a builder image (`builder`) to buid bitcoin from github sources, verifying version tag signatures;
2. we define a result image:
   1. installing the needed dependencies;
   2. copying libraries and binaries from the builder image;
   3. configuring the `bitcoin` user and the directories to which he will have access;
   4. setting the `entrypoint` (the script to run when the container starts).

### Configure

Create the bitcoin configuration file and populate it with the following content:

```sh
$ nano bitcoin-core/bitcoin.conf
```

```ini
# MobyBolt: bitcoind configuration
# /home/bitcoin/.bitcoin/bitcoin.conf

## Bitcoin daemon
server=1
txindex=1

# Additional logs
debug=tor
debug=i2p

# Disable debug.log
nodebuglogfile=1

# Enable all compact filters
blockfilterindex=1
# Support filtering of blocks and transactions with bloom filters
peerbloomfilters=1
# Serve compact block filters to peers per BIP 157
peerblockfilters=1
# Maintain coinstats index used by the gettxoutsetinfo RPC
coinstatsindex=1

# Avoid assuming that a block and its ancestors are valid,
# and potentially skipping their script verification.
# We will set it to 0, to verify all.
assumevalid=0

# Initial block download optimizations (set dbcache size in megabytes 
# (4 to 16384, default: 300) according to the available RAM of your device,
# recommended: dbcache=1/2 x RAM available e.g: 4GB RAM -> dbcache=2048)
# Remember to comment after IBD!
dbcache=8192
blocksonly=1

# Network
bind=0.0.0.0:8333
bind=0.0.0.0:8334=onion
listen=1

# Connect to clearnet using Tor SOCKS5 proxy
proxy=172.16.21.3:9050
onion=172.16.21.3:9050

# Tor control <ip:port> to use if onion listening enabled.
torcontrol=172.16.21.3:9051

# I2P SAM proxy to reach I2P peers and accept I2P connections
i2psam=172.16.21.4:7656

# RPC
rpcbind=0.0.0.0
rpcport=8332
rpcallowip=172.16.21.0/25
rpccookieperms=group

# ZMQ
zmqpubhashblock=tcp://0.0.0.0:8433
zmqpubrawblock=tcp://0.0.0.0:28332
zmqpubrawtx=tcp://0.0.0.0:28333
```

{:.more}
[Configuration options](https://en.bitcoin.it/wiki/Running_Bitcoin#Command-line_arguments){:target="_blank"} in Bitcoin Wiki

{:.warning}
`dbcache=...` need to be adjusted to your hardware capacity

#### Reject non-private networks (optional)

Add these lines to the end of the file if you want to only connect to onion or i2p peers. Save and exit.

```ini
# Reject non-private networks
onlynet=onion
onlynet=i2p
```

### Prepare the docker compose file

Create a bitcoin-specific docker compose file and populate it with the following contents:

```sh
$ nano bitcoin-core/docker-compose.yml
```

```yaml
services:
  bitcoin:
    build:
      context: .
      args:
        BITCOIN_VERSION: ${BITCOIN_VERSION}
        BITCOIN_GUID: ${BITCOIN_GUID}
        TOR_GUID: ${TOR_GUID}
    container_name: ${COMPOSE_PROJECT_NAME}_bitcoin
    depends_on:
      - tor
      - i2p
    expose:
      - "8332"
      - "8334"
    healthcheck:
      test: ["CMD-SHELL", "bitcoin-cli getconnectioncount | sed 's/^[1-9][0-9]*$/OK/' | grep OK || exit 1"]
      interval: 1m
      timeout: 10s
      retries: 3
      start_period: 5m
    image: ${COMPOSE_PROJECT_NAME}/bitcoin:${BITCOIN_VERSION}
    networks:
      backend:
        ipv4_address: ${BITCOIN_ADDRESS}
    restart: unless-stopped
    stop_grace_period: 5m
    volumes:
      - bitcoin-data:/home/bitcoin/.bitcoin/
      - ./bitcoin.conf:/home/bitcoin/.bitcoin/bitcoin.conf:ro
      - tor-data:/var/lib/tor/:ro

volumes:
  bitcoin-data:
```

{:.warning}
Be very careful to respect the indentation above, since yaml is very sensitive to this!

In this file:
1. we `build` the Dockerfile and create an image named `mobybolt/bitcoin:v28.1`;
2. we define a `healthcheck` that will check every minute that the bitcoin client is connected to at least one peer; 
3. we define the `restart` policy of the container in case of failures;
4. we provide the container with the `BITCOIN_ADDRESS` static address;
5. we provide the container with the previously defined configuration ([bind mount](https://docs.docker.com/storage/bind-mounts/){:target="_blank"}) and with a [volume](https://docs.docker.com/storage/volumes/){:target="_blank"} named `mobybolt_bitcoin-data` to store persistent data.

### Link the docker compose file

Link the bitcoin-specific docker compose file in the main one by running:

```sh
$ sed -i '/^networks:/i \ \ - bitcoin-core/docker-compose.yml' docker-compose.yml
```

The file should look like this:

```sh
$ cat docker-compose.yml
```

```yaml
include:
  - ...
  - bitcoin-core/docker-compose.yml
```

{:.warning}
Be very careful to respect the indentation above, since yaml is very sensitive to this!

### Test the docker compose file

Run the following command and check the output:

```sh
$ docker compose config --quiet && printf "OK\n" || printf "ERROR\n"
> OK
```

{:.hint}
If the output is `ERROR`, check the error reported... Maybe some wrong indentation in the yaml files?

---

## Build

Let's build the bitcoin image by typing:

```sh
$ docker compose build bitcoin
```

{:.warning}
This may take a long time

Check for a new image called `mobybolt/bitcoin:v28.1`:

```sh
$ docker images | grep "bitcoin\|TAG"
> REPOSITORY         TAG     IMAGE ID       CREATED              SIZE
> mobybolt/bitcoin   v28.1   30adc7959c8e   About a minute ago   795MB
```

## Run

Run the following command and check the output:

```sh
$ docker compose up -d bitcoin
> [+] Running 2/2
> ✔ Volume "mobybolt_bitcoin-data"  Created
> ✔ Container mobybolt_bitcoin      Started
```

Check the container logs:

```sh
$ docker compose logs bitcoin
> 2024-05-25T11:55:44Z Bitcoin Core version v28.1 (release build)
> ...
> 2024-05-25T11:55:44Z Default data directory /home/bitcoin/.bitcoin
> 2024-05-25T11:55:44Z Using data directory /home/bitcoin/.bitcoin
> 2024-05-25T11:55:44Z Config file: /home/bitcoin/.bitcoin/bitcoin.conf
> ...
> 2024-05-25T11:55:44Z [tor] Successfully connected!
> 2024-05-25T11:55:44Z [tor] Connected to Tor version 0.4.8.16
> 2024-05-25T11:55:44Z [tor] Supported authentication method: COOKIE
> 2024-05-25T11:55:44Z [tor] Supported authentication method: SAFECOOKIE
> 2024-05-25T11:55:44Z [tor] Using SAFECOOKIE authentication, reading cookie authentication from /var/lib/tor/control_auth_cookie
> ...
> 2024-05-25T11:55:44Z [tor] Authentication successful
```

Check the container status:

```sh
$ docker compose ps | grep "bitcoin\|NAME"
> NAME                      IMAGE                                  COMMAND                  SERVICE          CREATED      STATUS                PORTS
> mobybolt_bitcoin          mobybolt/bitcoin:v28.1   "docker-entrypoint.sh"   bitcoin          4 days ago   Up 3 days (healthy)   
```

{:.warning}
>The `STATUS` of the previous command must be `(healthy)`, or `(health: starting)`. Any other status is incorrect.
>
>If the container is in `(health: starting)` status, wait a few minutes and repeat the above command until the status changes to `(healthy)`. If this does not happen, the run has failed.

{:.note}
>If not already present, docker will also create the `mobybolt_bitcoin-data` volume. You can check for it with the command:
>
>```sh
>$ docker volume ls | grep "bitcoin\|DRIVER"
>> DRIVER    VOLUME NAME
>> local     mobybolt_bitcoin-data
>```

### Check bitcoin syncronization status

Run the following command:

```sh
$ docker compose exec bitcoin bitcoin-cli -getinfo
> Chain: main
> Blocks: 844910
> Headers: 844910
> Verification progress: 100.0000%
> ...
```

Bitcoin Core will be fully syncronized when the verification progress reaches 100% (or 99.xxx%).

### Check bitcoin networking status

Run the following command:

```sh
$ docker compose exec bitcoin bitcoin-cli -netinfo
> ...
>         onion     i2p   total   block
> in          0       2       2
> out         2       8      10       2
> total       2      10      12
> 
> Local addresses
> abcdef.onion     port   8333    score      4
> abcdef.b32.i2p   port      0    score      4
```

You should see some out connections and your onion/i2p local addresses.

---

## Bitcoin Core is syncing

This can take between one day and a week, depending mostly on your PC and network performance. It's best to wait until the synchronization is complete before going ahead.

### Explore bitcoin-cli

If everything is running smoothly, this is the perfect time to familiarize yourself with Bitcoin, the technical aspects of Bitcoin Core, and play around with bitcoin-cli until the blockchain is up-to-date.

- [The Little Bitcoin Book](https://littlebitcoinbook.com/){:target="_blank"} is a fantastic introduction to Bitcoin, focusing on the "why" and less on the "how"
- [Mastering Bitcoin](https://bitcoinbook.info/){:target="_blank"} by Andreas Antonopoulos is a great point to start, especially chapter 3:
   * You definitely need to have a [real copy](https://bitcoinbook.info/){:target="_blank"} of this book!
   * Read it online on [GitHub](https://github.com/bitcoinbook/bitcoinbook){:target="_blank"}
- [Learning Bitcoin from the Command Line](https://github.com/ChristopherA/Learning-Bitcoin-from-the-Command-Line/blob/master/README.md){:target="_blank"} by Christopher Allen gives a thorough deep dive into understanding the technical aspects of Bitcoin
- Also, check out the [bitcoin-cli reference](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list){:target="_blank"}

### Activate mempool & reduce dbcache after a full sync

Once Bitcoin Core is **fully synched**, we can reduce the size of the database cache. A bigger cache speeds up the initial block download, now we want to reduce memory consumption to allow the Lightning client and Electrum server to run in parallel. We also now want to enable the node to listen to and relay transactions.

Edit the bitcoin configuration file and comment (prepending a `#`) the following lines:

```sh
$ nano bitcoin-core/bitcoin.conf
```

```ini
#dbcache=2048
#blocksonly=1
#assumevalid=0
```

Restart Bitcoin Core:

```sh
$ docker compose restart bitcoin
> [+] Restarting 1/1
>  ✔ Container mobybolt_bitcoin  Started
```

---

## Upgrade

Check the [Bitcoin Core release page](https://github.com/bitcoin/bitcoin/releases){:target="_blank"} for a new version and change the `BITCOIN_VERSION` value in the `.env` file.
Then, redo the steps described in:

1. [Build](#build)
2. [Run](#run)

If everything is ok, you can clear the old image and build cache, like in the following example:

```sh
$ docker image ls | grep "bitcoin\|TAG"
> REPOSITORY         TAG                   IMAGE ID       CREATED          SIZE
> mobybolt/bitcoin   v28.1   30adc7959c8e   46 minutes ago   795MB
> mobybolt/bitcoin   v28.0   56f39c90e8ac   4 weeks ago      795MB
```

```sh
$ docker image rm mobybolt/bitcoin:v28.0
> Untagged: mobybolt/bitcoin:v28.0
> Deleted: sha256:56f39c90e8accbfae77a3c8ed9e6e5794d67c62d1944c2c0ce4c7bc3dd233f07
```

```sh
$ docker buildx prune
> WARNING! This will remove all dangling build cache. Are you sure you want to continue? [y/N] y
> ID                                              RECLAIMABLE     SIZE            LAST ACCESSED
> nd48am5z5nzmiiule5r8b1t8q*                      true            0B              About an hour ago
> ...
> Total:  5.711GB
```

---

## Uninstall

Follow the next steps to uninstall bitcoin:

1. Remove the container:

   ```sh
   $ docker compose down bitcoin
   > [+] Running 2/1
   > ✔ Container mobybolt_bitcoin  Removed
   > ...
   ```

2. Unlink the docker compose file:

   ```sh
   $ sed -i '/- bitcoin-core\/docker-compose.yml/d' docker-compose.yml
   ```

3. Remove the image:

   ```sh
   $ docker image rm $(docker images | grep bitcoin | awk '{print $3}')
   > Untagged: mobybolt/bitcoin:v28.1
   > Deleted: sha256:13afebf08e29c6b9a526a6e54ab1f93e745b25080add4e37af8f08bdf6cfbcc6
   ```

4. Clean the build cache:

   ```sh
   $ docker buildx prune
   > WARNING! This will remove all dangling build cache. Are you sure you want to continue? [y/N] y
   > ID                                              RECLAIMABLE     SIZE            LAST ACCESSED
   > 7r8ccrpq0g0e03deu2dh53ob6*                      true            9.69MB          19 minutes ago
   > ndrhcdo756vejnx17qm775t08*                      true            1.212kB         24 minutes ago
   > ...
   ```

5. Remove the volume (optional):

   ```sh
   $ docker volume rm mobybolt_bitcoin-data
   > mobybolt_bitcoin-data
   ```

   {:.warning}
   This will delete all bitcoin data, including all the synchronized blocks

6. Remove files and directories (optional):

   ```sh
   $ rm -rf bitcoin-core
   ```

7. Cleanup the env (optional)

   ```sh
   $ sed -i '/^BITCOIN_/d' .env
   ```

---

[<< Bonus Section](../)