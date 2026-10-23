---
layout: default
title: Bitcoin client
nav_order: 10
parent: + Bitcoin
grand_parent: MobyBolt
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Bitcoin client
{:.no_toc}

{: .text-center}
![Bitcoin Roots logo](data:image/svg+xml,<?xml version='1.0' encoding='UTF-8'?><svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512' width='1in' height='1in' role='img' aria-labelledby='title desc'><title id='title'>Bitcoin Roots icon</title><desc id='desc'>Bitcoin-style B with branching roots, recreated as vector outlines from the approved Bitcoin Roots design.</desc><g id='logo'><path fill='%23F57C00' fill-rule='evenodd' transform='translate(57.25 35.5) scale(1.5)' d='M122,285.97 C117.93,278 119.23,267.42 118,258.29 C109.4,264.16 105.93,272.62 101,281.29 C99.18,278.46 99.22,276.31 100.29,273 L102.7,265 L113.28,251 C116.82,241.1 114.35,233.66 109,224.85 C91.85,232.74 97.9,253.09 88,265.41 C85.05,269.07 81.2,271.75 77,273.69 L73.6,275 C72.16,272.21 78.24,269.1 79.3,267 C83.39,258.82 87.23,251.69 86,242.29 C77.17,246.42 65.77,257.82 58.67,260 C63.38,246.34 77.11,240.54 87,231.49 L93,223.59 C99.05,216.06 106.43,210.91 105,200.29 L93,209.3 C85.45,213.03 76.91,215.35 70.6,221 C60.72,229.86 55.27,242.88 47,252.93 C46.62,247.72 49.39,242.24 49,237.62 C43.87,239.13 38.11,240.75 34,244.51 L28,248.69 L28.31,246 L34,238.5 C42.23,230.27 57.02,229.58 60,216.86 C49.36,215.9 39.01,217.35 29,220.71 L11.67,229 C10,223.24 30.92,212.18 35,210.3 C42.44,206.88 51.95,207.33 60,206.48 C74.25,204.98 93.8,193.96 95.48,178 C96,174 95,174 91,174 H58 V154 H74 Q83,154 83,145 V71 Q83,62 75,62 H58 V41 H95 V9 H118 V41 H134 V9 H155 V41 C184,41 201,52 201,73 C201,86 195,95 184,101 C202,107 210,119 210,134 C210,161 192,175 165,175 H151 C147.68,195.85 176.32,204.83 192,206.48 C197.95,207.11 204.33,205.46 210,207.29 C213.89,208.54 218.68,207.89 223,209.29 C231.77,212.12 239.77,215.27 246.5,222 L251,227.44 L252,229.38 C250.3,230.25 240.55,223.57 238,222.71 C225.57,218.54 213.24,214.87 199.86,217 C205.41,236.78 229.85,231.25 232,250.69 C227.56,247.68 223.35,243.51 218,241.71 C212.23,239.78 206.56,239.05 201,236.3 C192.78,232.23 190.49,220.79 181,217.71 L162,214.29 C153.35,211.48 147.22,205.22 140,200.29 C136.76,224.32 160.15,231.72 178,237.71 L187,243.3 C191.66,245.63 204.21,259.72 203.37,265 C203.07,266.85 192.49,256.87 191,255.51 C186.46,251.35 164.22,239.78 159,241.86 L161.29,251 C165.01,262.15 172.4,266.83 177.33,276 C159.1,271.99 154.54,255.65 147.3,241 C144.04,234.41 136.91,230.48 133.7,224 C125.74,207.9 126.5,191.82 126.5,174 L127,154 H138 C160,154 170,147 170,135 C170,121 157,117 141,117 H119 V153 C116.02,176.33 115.28,204.85 122.71,227 L131.7,246 C135.32,253.32 143.51,258.14 144.52,267 C144.93,270.67 145.51,274.11 145.5,278 L145,282.12 C142.71,282.38 140.98,273.06 140.29,271 C138.16,264.65 131.33,257.93 126,254.29 C125.14,260.67 125.19,267.65 124.52,274 C124.06,278.31 124.52,282.63 122,285.97 Z M119,62 V97 H136 C152,97 162,91 162,80 C162,68 152,62 137,62 Z'/></g></svg>){: width="20%"}


We install [Bitcoin Roots](https://bitcoincore.org/){:target="_blank"}, the reference client implementation of the Bitcoin network.

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

Let's create the directory structure for Bitcoin Roots:

```sh
$ mkdir -p bitcoin-core/patches
```

### Prepare the environment

Edit the `.env` file and append the following content to the end:

```sh
$ nano .env
```

```ini
# bitcoin
BITCOIN_VERSION=v29.4
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
        build-essential \
        ccache \
        cmake \
        curl \
        git \
        gpg \
        pkgconf \
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
    # imports automatically all signatures from the Bitcoin Roots release attestations (Guix) repository
    curl -s \
        $BITCOIN_KEYS_URL |\
        grep download_url |\
        grep -oE "https://[a-zA-Z0-9./-]+" |\
        while read url; do \
            curl -s "$url" |\
            gpg --import; \
        done

# copy patches
COPY patches/ /patches/

WORKDIR bitcoin

RUN set -xe && \
    # verify signature
    git verify-tag $BITCOIN_VERSION && \
    # apply patches (if any)
    for patch in $( find /patches -type f ); do \
        git apply $patch; \
    done && \
    # build
    cmake -B build -DWITH_ZMQ=ON && \
    cmake --build build -j $(nproc) && \
    # install
    cmake --install build


# result image
FROM debian:stable-slim

# copy bitcoin binaries and libraries
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
        adduser \
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

### Ordisrespector patch filter (optional)

Download the Ordisrespector patch, an Ordinals NFTs spam filter for mempool politics of Bitcoin Roots:

```sh
$ wget -P bitcoin-core/patches https://raw.githubusercontent.com/tulliolo/mobybolt/master/resources/ordisrespector.patch
```

The downloaded patch will be automatically applied in the [Build](#build) stage.

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

# Set OP_RETURN limit to value before v30.0
datacarriersize=83

# Append comment to the user agent string
uacomment=MobyBolt node

# Disable integrated wallet
disablewallet=1

# Additional logs
debug=tor
debug=i2p
## Include peers IP addresses in log output (optional)
logips=1

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
1. we `build` the Dockerfile and create an image named `mobybolt/bitcoin:v29.4`;
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

Check for a new image called `mobybolt/bitcoin:v29.4`:

```sh
$ docker images | grep "bitcoin\|TAG"
> REPOSITORY         TAG     IMAGE ID       CREATED              SIZE
> mobybolt/bitcoin   v29.4   30adc7959c8e   About a minute ago   795MB
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
> 2024-05-25T11:55:44Z Bitcoin Core version v29.4 (release build)
> ...
> 2024-05-25T11:55:44Z Default data directory /home/bitcoin/.bitcoin
> 2024-05-25T11:55:44Z Using data directory /home/bitcoin/.bitcoin
> 2024-05-25T11:55:44Z Config file: /home/bitcoin/.bitcoin/bitcoin.conf
> ...
> 2024-05-25T11:55:44Z [tor] Successfully connected!
> 2024-05-25T11:55:44Z [tor] Connected to Tor version 0.4.9.14
> 2024-05-25T11:55:44Z [tor] Supported authentication method: COOKIE
> 2024-05-25T11:55:44Z [tor] Supported authentication method: SAFECOOKIE
> 2024-05-25T11:55:44Z [tor] Using SAFECOOKIE authentication, reading cookie authentication from /var/lib/tor/control_auth_cookie
> ...
> 2024-05-25T11:55:44Z [tor] Authentication successful
```

Check the container status:

```sh
$ docker compose ps | grep "bitcoin\|NAME"
> NAME                      IMAGE                    COMMAND                  SERVICE          CREATED      STATUS                PORTS
> mobybolt_bitcoin          mobybolt/bitcoin:v29.4   "docker-entrypoint.sh"   bitcoin          4 days ago   Up 3 days (healthy)   8332/tcp, 8334/tcp  
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

Bitcoin Roots will be fully syncronized when the verification progress reaches 100% (or 99.xxx%).

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

## Bitcoin Roots is syncing

This can take between one day and a week, depending mostly on your PC and network performance. It's best to wait until the synchronization is complete before going ahead.

### Explore bitcoin-cli

If everything is running smoothly, this is the perfect time to familiarize yourself with Bitcoin, the technical aspects of Bitcoin Roots, and play around with bitcoin-cli until the blockchain is up-to-date.

- [The Little Bitcoin Book](https://littlebitcoinbook.com/){:target="_blank"} is a fantastic introduction to Bitcoin, focusing on the "why" and less on the "how"
- [Mastering Bitcoin](https://bitcoinbook.info/){:target="_blank"} by Andreas Antonopoulos is a great point to start, especially chapter 3:
   * You definitely need to have a [real copy](https://bitcoinbook.info/){:target="_blank"} of this book!
   * Read it online on [GitHub](https://github.com/bitcoinbook/bitcoinbook){:target="_blank"}
- [Learning Bitcoin from the Command Line](https://github.com/ChristopherA/Learning-Bitcoin-from-the-Command-Line/blob/master/README.md){:target="_blank"} by Christopher Allen gives a thorough deep dive into understanding the technical aspects of Bitcoin
- Also, check out the [bitcoin-cli reference](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list){:target="_blank"}

### Activate mempool & reduce dbcache after a full sync

Once Bitcoin Roots is **fully synched**, we can reduce the size of the database cache. A bigger cache speeds up the initial block download, now we want to reduce memory consumption to allow the Lightning client and Electrum server to run in parallel. We also now want to enable the node to listen to and relay transactions.

Edit the bitcoin configuration file and comment (prepending a `#`) the following lines:

```sh
$ nano bitcoin-core/bitcoin.conf
```

```ini
#dbcache=2048
#blocksonly=1
#assumevalid=0
```

Restart Bitcoin Roots:

```sh
$ docker compose restart bitcoin
> [+] Restarting 1/1
>  ✔ Container mobybolt_bitcoin  Started
```

---

## Upgrade

Check the [Bitcoin Roots release page](https://github.com/bitcoin/bitcoin/releases){:target="_blank"} for a new version and change the `BITCOIN_VERSION` value in the `.env` file.
Then, redo the steps described in:

1. [Prepare the Dockerfile](#prepare-the-dockerfile)
2. [Build](#build)
3. [Run](#run)

If everything is ok, you can clear the old image and build cache, like in the following example:

```sh
$ docker image ls | grep "bitcoin\|TAG"
> REPOSITORY         TAG     IMAGE ID       CREATED          SIZE
> mobybolt/bitcoin   v29.4   30adc7959c8e   46 minutes ago   795MB
> mobybolt/bitcoin   v29.3   56f39c90e8ac   4 weeks ago      795MB
```

```sh
$ docker image rm mobybolt/bitcoin:v29.3
> Untagged: mobybolt/bitcoin:v29.3
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
   > Untagged: mobybolt/bitcoin:v29.4
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

{:.d-flex .flex-justify-between}
[<< I2P project](../setup/i2p-project)
[Electrum server >>](electrum-server)