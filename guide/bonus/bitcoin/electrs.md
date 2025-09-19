---
layout: default
title: Electrs
parent: + Bitcoin
grand_parent: Bonus Section
nav_exclude: true
has_toc: false
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Electrum server
{:.no_toc}

{: .text-center}
![electrs logo](../../../images/bonus-bitcoin-electrs_logo.svg){: width="70%"}

We install [Electrs](https://github.com/romanz/electrs){:target="_blank"}, a light SPV server for Bitcoin created by Roman Zeyde. It can be used as an alternative to [Fulcrum](https://github.com/cculianu/Fulcrum){:target="_blank"}.

If you prefer to install Fulcrum, please follow this [guide](../../mobybolt/bitcoin/electrum-server).

{:.note}
Electrs and Fulcrum can still coexist in MobyBolt, since they use different IPs and ports.

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

## Bitcoin with hardware wallets

The best way to safely keep your bitcoin (meaning the best combination of security and usability) is to use a hardware wallet (like [BitBox](https://shiftcrypto.ch/bitbox02){:target="_blank"}, [Coldcard](https://coldcard.com/){:target="_blank"}, or [Trezor](https://trezor.io/){:target="_blank"}) in combination with your own Bitcoin node. This gives you security, privacy and eliminates the need to trust a third party to verify transactions.

The Bitcoin client on MobyBolt itself is not meant to hold funds.

One possibility to use the Bitcoin client with your Bitcoin wallets is to use an Electrum server as middleware. It imports data from the Bitcoin client and provides it to software wallets supporting the Electrum protocol. Desktop wallets like [Sparrow](https://sparrowwallet.com/){:target="_blank"}, the [BitBoxApp](https://shiftcrypto.ch/app/){:target="_blank"}, [Electrum](https://electrum.org/){:target="_blank"}, or [Specter Desktop](https://specter.solutions/desktop/){:target="_blank"} that support hardware wallets can then be used with your own sovereign Bitcoin node.

## Prepare

Create the electrs directory:

```sh
$ mkdir electrs
```

### Prepare the environment

Edit the `.env` file and append the following content to the end:

```sh
$ nano .env
```

```ini
# electrs
ELECTRS_VERSION=v0.10.9
ELECTRS_ADDRESS=172.16.21.13
ELECTRS_GUID=1103
```

In this file:
1. we define the `ELECTRS_VERSION` (check the latest available version [here](https://github.com/romanz/electrs/releases){:target="_blank"});
2. we define a static address for the container;
3. we define the `guid` (group and user id) of the electrs user.

### Prepare the Dockerfile

Create the [Dockerfile](https://docs.docker.com/reference/dockerfile/){:target="_blank"} and populate it with the following content:

```sh
$ nano electrs/Dockerfile
```

```Dockerfile
# base image
FROM debian:stable-slim AS base

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
        cargo \
        clang \
        cmake \
        curl \
        git \
        gpg && \
    rm -rf /var/lib/apt/lists/*


# builder image
FROM base AS builder

ARG ELECTRS_VERSION

ENV ELECTRS_URL="https://github.com/romanz/electrs.git" \
    ELECTRS_SIG_URL="https://romanzey.de/pgp.txt"

# clone repository
RUN set -eux && \
    git clone --branch $ELECTRS_VERSION $ELECTRS_URL

WORKDIR electrs

# build electrs
RUN set -eux && \
    # import signatures
    curl $ELECTRS_SIG_URL | gpg --import && \
    # verify signatures
    git verify-tag $ELECTRS_VERSION && \
    # build
    cargo build --locked --release && \
    # install
    install -m 0755 -o root -g root -t /usr/local/bin ./target/release/electrs


# result image
FROM debian:stable-slim

COPY --from=builder /usr/local/ /usr/local/

# default guid for electrs user
ARG ELECTRS_GUID=1101
ARG BITCOIN_GUID=1100

RUN set -xe && \
    # create electrs user
    adduser --disabled-password --comment "" --uid $ELECTRS_GUID electrs && \
    # create bitcoin group and add electrs user to bitcoin group
    addgroup --gid $BITCOIN_GUID bitcoin && \
    adduser electrs bitcoin && \
    # setup dirs and permissions
    mkdir -p /home/electrs/db/ && \
    chmod 0700 /home/electrs/db/ && \
    chown -R electrs:electrs /home/electrs/db/

# switch user
USER electrs

# setup entrypoint
ENTRYPOINT ["electrs"]
CMD ["--conf", "/home/electrs/electrs.conf", "--skip-default-conf-files"]
```

In this file:
1. we define a builder image (`builder`) to buid electrs from github sources, verifying version tag signatures;
2. we define a result image:
   1. copying binaries from builder image;
   2. configuring the `electrs` user and the directories to which he will have access;
   3. adding the `electrs` user to the `bitcoin` group for RPC cookie authentication;
   4. setting the `entrypoint` (the script to run when the container starts).

### Configure Electrs

Create the Electrs configuration file and populate it with the following content:

```sh
$ nano electrs/electrs.conf
```

```ini
# MobyBolt: electrs configuration
# /home/electrs/electrs.conf

# Bitcoin Core settings
network = "bitcoin"
daemon_dir = "/data/bitcoin"
daemon_rpc_addr = "bitcoin:8332"
daemon_p2p_addr = "bitcoin:8333"

# Electrs settings
electrum_rpc_addr = "0.0.0.0:50001"
db_dir = "/home/electrs/db"
server_banner = "Welcome to electrs (Electrum Rust Server) running on a MobyBolt node!"
skip_block_download_wait = true

# Logging
log_filters = "INFO"
```

### Prepare the docker compose file

Create the [docker compose file](https://qubitpi.github.io/docker-docs/compose/compose-yaml-file/){:target="_blank"} and populate it with the following content:

```sh
$ nano electrs/docker-compose.yml
```

```yaml
services:
  electrs:
    build:
      context: .
      args:
        ELECTRS_VERSION: ${ELECTRS_VERSION}
        ELECTRS_GUID: ${ELECTRS_GUID}
        BITCOIN_GUID: ${BITCOIN_GUID}
    container_name: ${COMPOSE_PROJECT_NAME}_electrs
    depends_on:
      bitcoin:
        condition: service_healthy
    expose:
      - "50001:50001"
    image: ${COMPOSE_PROJECT_NAME}/electrs:${ELECTRS_VERSION}
    networks:
      backend:
        ipv4_address: ${ELECTRS_ADDRESS}
    restart: unless-stopped
    stop_grace_period: 3m
    volumes:
      - electrs-data:/home/electrs/db/
      - bitcoin-data:/data/bitcoin/:ro
      - ./electrs.conf:/home/electrs/electrs.conf:ro

volumes:
  electrs-data:
```

In this file:
1. we `build` the Dockerfile and create an image named `mobybolt/electrs:v0.10.9`;
2. we define the `restart` policy of the container in case of failures;
3. we declare the bitcoin service as a dependency (Electrs will not run if bitcoin is not active);
4. we provide the container:
   1. with the previously defined configuration ([bind mount](https://docs.docker.com/storage/bind-mounts/){:target="_blank"});
   2. with the bitcoin volume data, from which it will reach the RPC authentication cookie;
   3. with a [volume](https://docs.docker.com/storage/volumes/){:target="_blank"} named `mobybolt_electrs-data` to store persistent data;
   4. with the `ELECTRS_ADDRESS` static address.

### Link the docker compose File

Link the electrs-specific docker compose file in the main one by running:

```sh
$ sed -i '/^networks:/i \ \ - electrs/docker-compose.yml' docker-compose.yml
```

The file should look like this:

```sh
$ cat docker-compose.yml
```

```yaml
include:
  - ...
  - electrs/docker-compose.yml
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

Let's build the electrs image by typing:

```sh
$ docker compose build electrs
```

Check for a new image called `mobybolt/electrs:v0.10.9`:

```sh
$ docker images | grep "electrs\|TAG"
> REPOSITORY          TAG        IMAGE ID       CREATED              SIZE
> mobybolt/electrs    v0.10.9    03c38d632c76   About a minute ago   93MB
```

---

## Run

Run the following command and check the output:

```sh
$ docker compose up -d electrs
> [+] Running 2/2
> ✔ Volume "mobybolt_electrs-data"  Created
> ✔ Container mobybolt_electrs      Started
```

Check the container logs:

```sh
$ docker compose logs electrs
> mobybolt_electrs  | Starting electrs 0.10.9 on x86_64 linux with Config { network: Bitcoin, db_path: "/home/electrs/db/bitcoin", db_log_dir: None, db_parallelism: 1, daemon_auth: CookieFile("/data/bitcoin/.cookie"), daemon_rpc_addr: 172.16.21.10:8332, daemon_p2p_addr: 172.16.21.10:8333, electrum_rpc_addr: 0.0.0.0:50001, monitoring_addr: 127.0.0.1:4224, wait_duration: 10s, jsonrpc_timeout: 15s, index_batch_size: 10, index_lookup_limit: None, reindex_last_blocks: 0, auto_reindex: true, ignore_mempool: false, sync_once: false, skip_block_download_wait: true, disable_electrum_rpc: false, server_banner: "Welcome to electrs (Electrum Rust Server) running on a MobyBolt node!", signet_magic: f9beb4d9 }
> mobybolt_electrs  | [2025-03-21T17:40:44.981Z INFO  electrs::metrics::metrics_impl] serving Prometheus metrics on 127.0.0.1:4224
> mobybolt_electrs  | [2025-03-21T17:40:44.981Z INFO  electrs::server] serving Electrum RPC on 0.0.0.0:50001
> mobybolt_electrs  | [2025-03-21T17:40:45.104Z INFO  electrs::db] "/home/electrs/db/bitcoin": 0 SST files, 0 GB, 0 Grows
> mobybolt_electrs  | [2025-03-21T17:40:45.165Z INFO  electrs::index] indexing 2000 blocks: [1..2000]
> mobybolt_electrs  | [2025-03-21T17:40:45.470Z INFO  electrs::chain] chain updated: tip=00000000dfd5d65c9d8561b4b8f60a63018fe3933ecb131fb37f905f87da951a, height=2000
> mobybolt_electrs  | [2025-03-21T17:40:45.474Z INFO  electrs::index] indexing 2000 blocks: [2001..4000]
> mobybolt_electrs  | [2025-03-21T17:40:45.719Z INFO  electrs::chain] chain updated: tip=00000000922e2aa9e84a474350a3555f49f06061fd49df50a9352f156692a842, height=4000
> ...
```

Check the container status:

```sh
$ docker compose ps | grep "electrs\|NAME"
> NAME                IMAGE                      COMMAND                  SERVICE    CREATED          STATUS          PORTS
> mobybolt_electrs    mobybolt/electrs:v0.10.9   "electrs --conf /hom…"   electrs    48 minutes ago   Up 48 minutes   0/tcp                                                                                              mobybolt_electrs
```

{:.note}
>If not already present, docker will also create the `mobybolt_electrs-data` volume. You can check for it with the command:
>
>```sh
>$ docker volume ls | grep "electrs\|DRIVER"
>> DRIVER    VOLUME NAME
>> local     mobybolt_electrs-data
>```

Electrs will now index the whole Bitcoin blockchain so that it can provide all necessary information to wallets. With this, the wallets you use no longer need to connect to any third-party server to communicate with the Bitcoin peer-to-peer network.

---

## Remote access over SSL/TLS

We'll use nginx to connect a wallet in our LAN to electrs.

To perform this configuration:

- create the electrs-reverse-proxy configuration file with the following contents:

  ```sh
  $ nano nginx/streams-enabled/electrs-reverse-proxy.conf
  ```

  ```nginx
  upstream electrs {
    server 172.16.21.13:50001;
  }
  server {
    listen 50004 ssl;
    proxy_pass electrs;
  }
  ```

- test nginx configuration:

  ```sh
  $ docker exec mobybolt_nginx nginx -t
  > nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
  > nginx: configuration file /etc/nginx/nginx.conf test is successful
  ```

- Open the electrs port in the nginx docker compose:

  ```sh
  $ grep '^ *ports:' nginx/docker-compose.yml || sed -i '/restart:/i  \ \ \ \ ports:' nginx/docker-compose.yml
  $ sed -i '/restart:/i  \ \ \ \ \ \ \- 50004:50004 # electrs' nginx/docker-compose.yml
  ```
  
  The file should now look like this:

  ```sh
  $ cat nginx/docker-compose.yml
  > ...
  > image: ${COMPOSE_PROJECT_NAME}/nginx:${NGINX_VERSION}
  > ports:
  >   ...
  >   - "50004:50004" # electrs
  > restart: unless-stopped
  > ...
  ```

  This configuration will allow the Electrs ssl/tls port in the docker-managed firewall.

  {:.warning}
  Be very careful to respect the indentation above, since yaml is very sensitive to this!

- test the docker compose file:

  ```sh
  $ docker compose config --quiet && printf "OK\n" || printf "ERROR\n"
  > OK
  ```

- recreate the nginx container:

  ```sh
  $ docker compose down nginx && docker compose up -d nginx
  > [+] Running 2/1
  >  ✔ Container mobybolt_nginx  Removed                                                                                                0.8s 
  >  ! Network mobybolt_default  Resource is still in use                                                                               0.0s 
  > [+] Running 1/1
  >  ✔ Container mobybolt_nginx  Started
  ```

- check the nginx container status (it should be `healthy`, if not repeat the command):

  ```sh
  $ docker compose ps | grep "nginx\|NAME"
  > NAME             IMAGE                     COMMAND                  SERVICE    CREATED       STATUS                   PORTS
  > mobybolt_nginx   mobybolt/nginx:mainline   "/docker-entrypoint.…"   nginx      2 hours ago   Up 5 minutes (healthy)   80/tcp, 0.0.0.0:50004->50004/tcp, :::50004->50004/tcp
  ```

---

## Remote access over Tor

- Edit the tor configuration file, adding the following content at the end:

  ```sh
  $ nano tor/torrc
  ```

  ```conf
  # Hidden Service Electrs
  HiddenServiceDir /var/lib/tor/hidden_service_electrs/
  HiddenServiceVersion 3
  HiddenServicePoWDefensesEnabled 1
  HiddenServicePort 50003 172.16.21.13:50001
  ```

- Check the tor configuration file:

  ```sh
  $ docker compose exec -u tor tor tor -f /etc/tor/torrc --verify-config
  > ...
  > Configuration was valid
  ```

- Restart tor:

  ```sh
  $ docker compose restart tor
  > [+] Restarting 1/1
  >  ✔ Container mobybolt_tor  Started
  ```

- check the tor container status (it should be `healthy`, if not repeat the command):

  ```sh
  $ docker compose ps | grep "tor\|NAME"
  > NAME           IMAGE                   COMMAND                  SERVICE    CREATED       STATUS                        PORTS
  > mobybolt_tor   mobybolt/tor:0.4.8.18   "docker-entrypoint.sh"   tor        3 hours ago   Up About a minute (healthy)   9050-9051/tcp
  ```

- get your onion address:

  ```sh
  $ docker compose exec tor cat /var/lib/tor/hidden_service_electrs/hostname
  > abcdefg..............xyz.onion
  ```

---

## Upgrade

Check the [Electrs release page](https://github.com/romanz/electrs/releases){:target="_blank"} for a new version and change the `ELECTRS_VERSION` value in the `.env` file.
Then, redo the steps described in:

1. [Build](#build)
2. [Run](#run)

If everything is ok, you can clear the old image and build cache, like in the following example:

```sh
$ docker images | grep "electrs\|TAG"
> REPOSITORY           TAG       IMAGE ID       CREATED          SIZE
> mobybolt/electrs     v0.10.9   03c38d632c76   3 minutes ago    93MB
> mobybolt/electrs     v0.10.8   3613ae3d3613   14 minutes ago   92MB
```

```sh
$ docker image rm mobybolt/electrs:v0.10.8
> Untagged: mobybolt/electrs:v0.10.8
> Deleted: sha256:3613ae3d36137e9e4dd38e93d40edd21b8e4aa17df5527e934aed2013087537a
```

```sh
$ docker buildx prune
> WARNING! This will remove all dangling build cache. Are you sure you want to continue? [y/N] y
> ID                                              RECLAIMABLE     SIZE            LAST ACCESSED
> pbzeixdrvu87hv3rajkrfprr8                       true            398B            24 minutes ago
> xdufppotcvx2kegu5gc3zscg6*                      true            621.8MB         17 minutes ago
> ...
> Total:  1.853GB
```

---

## Uninstall

Follow the next steps to uninstall electrs:

1. Unlink nginx:
   
   - remove electrs port:

     ```sh
     $ rm -f nginx/config/streams-enabled/electrs-reverse-proxy.conf
     $ sed -i '/50004:50004/d' nginx/docker-compose.yml
     $ grep -A 1 '^ *ports:' nginx/docker-compose.yml | grep '^ *-' || sed -i '/^ *ports:/d' nginx/docker-compose.yml
     ```

   - test the docker compose file:
   
     ```sh
     $ docker compose config --quiet && printf "OK\n" || printf "ERROR\n"
     > OK
     ```
   
   - recreate the nginx container:
   
     ```sh
     $ docker compose down nginx && docker compose up -d nginx
     > [+] Running 2/1
     >  ✔ Container mobybolt_nginx     Removed                                                                                                0.8s 
     >  ! Network mobybolt_default  Resource is still in    use                                                                               0.0s 
     > [+] Running 1/1
     >  ✔ Container mobybolt_nginx  Started
     ```
   
   - check the nginx container status (it should be `healthy`, if not repeat the command):
   
     ```sh
     $ docker compose ps | grep "nginx\|NAME"
     > NAME             IMAGE                     COMMAND                  SERVICE    CREATED       STATUS                      PORTS
     > mobybolt_nginx   mobybolt/nginx:mainline   "/docker-entrypoint.…"   nginx      2 hours ago   Up 5 minutes (healthy)      80/tcp, 0.0.0.0:50004->50004/tcp, :::50004->50004/tcp
     ```

2. Unlink tor:

   - edit tor configuration and remove the following lines:

     ```sh
     $ nano tor/torrc
     ```
  
     ```conf
     # Hidden Service Electrs
     HiddenServiceDir /var/lib/tor/hidden_service_electrs/
     HiddenServiceVersion 3
     HiddenServicePoWDefensesEnabled 1
     HiddenServicePort 50003 172.16.21.13:50001
     ```

   - restart tor:

     ```sh
     $ docker compose restart tor
     ```

   - check the tor container status (it should be `healthy`, if not repeat the command):
   
     ```sh
     $ docker compose ps | grep "tor\|NAME"
     > NAME           IMAGE                   COMMAND                   SERVICE    CREATED       STATUS                      PORTS
     > mobybolt_tor   mobybolt/tor:0.4.8.18   "/docker-entrypoint.sh"   tor        2 hours ago   Up 5 minutes (healthy)      9050-9051/tcp
     ```

3. Remove the container:

   ```sh
   $ docker compose down electrs
   > [+] Running 2/1
   > ✔ Container mobybolt_electrs  Removed
   > ...
   ```

4. Unlink the docker compose file:

   ```sh
   $ sed -i '/- electrs\/docker-compose.yml/d' docker-compose.yml
   ```

5. Remove the image:

   ```sh
   $ docker image rm $(docker images | grep electrs | awk '{print $3}')
   > Untagged: mobybolt/electrs:v0.10.9
   > Deleted: sha256:13afebf08e29c6b9a526a6e54ab1f93e745b25080add4e37af8f08bdf6cfbcc6
   ```

6. Clean the build cache:

   ```sh
   $ docker buildx prune
   > WARNING! This will remove all dangling build cache. Are you sure you want to continue? [y/N] y
   > ID                                              RECLAIMABLE     SIZE            LAST ACCESSED
   > 7r8ccrpq0g0e03deu2dh53ob6*                      true            9.69MB          19 minutes ago
   > ndrhcdo756vejnx17qm775t08*                      true            1.212kB         24 minutes ago
   > ...
   ```

7. Remove the volume (optional):

   ```sh
   $ docker volume rm mobybolt_electrs-data
   > mobybolt_electrs-data
   ```

8. Remove files and directories (optional):

   ```sh
   $ rm -rf electrs
   ```

9. Cleanup the env (optional)

   ```sh
   $ sed -i '/^ELECTRS_/d' .env
   ```

---

[<< Bonus Section](../)