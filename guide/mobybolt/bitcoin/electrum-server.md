---
layout: default
title: Electrum server
nav_order: 20
parent: + Bitcoin
grand_parent: MobyBolt
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Electrum server
{:.no_toc}

{: .text-center}
![fulcrum logo](../../../images/mobybolt-bitcoin-electrum-server_logo.png){: width="20%"}

We install [Fulcrum](https://github.com/cculianu/Fulcrum){:target="_blank"}, a fast & nimble SPV server for Bitcoin created by Calin Culianu. It can be used as an alternative to [Electrs](https://github.com/romanz/electrs){:target="_blank"} because of its performance, as we can see in Craig Raw's [comparison](https://www.sparrowwallet.com/docs/server-performance.html){:target="_blank"} of servers.

If you prefer to install Electrs, please follow this [bonus guide](../../bonus/bitcoin/electrs).

{:.note}
Fulcrum and Electrs can still coexist in MobyBolt, since they use different IPs and ports.

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

Create the fulcrum directory:

```sh
$ mkdir fulcrum
```

### Prepare the environment

Edit the `.env` file and append the following content to the end:

```sh
$ nano .env
```

```ini
# fulcrum
FULCRUM_VERSION=v1.12.0
FULCRUM_ADDRESS=172.16.21.11
FULCRUM_GUID=1101
```

In this file:
1. we define the `FULCRUM_VERSION` (check the latest available version [here](https://github.com/cculianu/Fulcrum/releases){:target="_blank"});
2. we define a static address for the container;
3. we define the `guid` (group and user id) of the fulcrum user.

### Prepare the banner

Create the banner file with the following content (it will be shown when Fulcrum starts):

```sh
$ nano fulcrum/fulcrum-banner.txt
```

```
    ______      __                            
   / ____/_  __/ /___________  ______ ___     
  / /_  / / / / / ___/ ___/ / / / __ `__ \    
 / __/ / /_/ / / /__/ /  / /_/ / / / / / /    
/_/    \__,_/_/\___/_/   \__,_/_/ /_/ /_/     
    __  ___      __          ____        ____ 
   /  |/  /___  / /_  __  __/ __ )____  / / /_
  / /|_/ / __ \/ __ \/ / / / __  / __ \/ / __/
 / /  / / /_/ / /_/ / /_/ / /_/ / /_/ / / /_  
/_/  /_/\____/_.___/\__, /_____/\____/_/\__/  
                   /____/                     
```

### Prepare the Dockerfile

Create the [Dockerfile](https://docs.docker.com/reference/dockerfile/){:target="_blank"} and populate it with the following content:

```sh
$ nano fulcrum/Dockerfile
```

```Dockerfile
# base image
FROM debian:stable-slim AS base

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
        build-essential \
        curl \
        git \
        libbz2-dev \
        libjemalloc-dev \
        libminiupnpc-dev \
        libzmq3-dev \
        pkg-config \
        qt5-qmake \
        qtbase5-dev \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*


# builder image
FROM base AS builder

ARG FULCRUM_VERSION

ENV FULCRUM_URL="https://github.com/cculianu/Fulcrum.git"

RUN set -eux && \
    # download repository
    git clone --branch $FULCRUM_VERSION $FULCRUM_URL

WORKDIR /Fulcrum

# install fulcrum
RUN set -eux && \
    # verify signatures
    git checkout $FULCRUM_VERSION && \
    # configure
    qmake -makefile PREFIX=/usr/local Fulcrum.pro && \
    # build
    make -j$(nproc) && \
    # install
    make install


# result image
FROM debian:stable-slim

COPY --from=builder /usr/local/ /usr/local/

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
        libjemalloc-dev \
        libminiupnpc17 \
        libqt5network5 \
        libzmq3-dev \
        python3 && \
    rm -rf /var/lib/apt/lists/*

# default uid for fulcrum user
ARG FULCRUM_GUID=1101
ARG BITCOIN_GUID=1100

RUN set -xe && \
    # create fulcrum user
    adduser --disabled-password --comment "" --uid $FULCRUM_GUID fulcrum && \
    # create bitcoin group and add fulcrum user to bitcoin group
    addgroup --gid $BITCOIN_GUID bitcoin && \
    adduser fulcrum bitcoin && \
    # setup dirs and permissions
    mkdir -p /home/fulcrum/db/ /run/fulcrum/ && \
    chmod 0700 /home/fulcrum/db/ /run/fulcrum/ && \
    chown fulcrum:fulcrum /home/fulcrum/db/ /run/fulcrum/

# switch user
USER fulcrum
COPY ./fulcrum-banner.txt /home/fulcrum/.fulcrum/

# setup entrypoint
ENTRYPOINT ["Fulcrum"]
CMD ["/home/fulcrum/fulcrum.conf"]
```

In this file:
1. we define a builder image (`builder`) to buid fulcrum from github sources, verifying version tag signatures;
2. we define a result image:
   1. installing some needed dependencies;
   2. copying binaries from builder image;
   3. configuring the `fulcrum` user and the directories to which he will have access;
   4. adding the `fulcrum` user to the `bitcoin` group for RPC cookie authentication;
   5. setting the `entrypoint` (the script to run when the container starts).

### Configure Fulcrum

Create the Fulcrum configuration file and populate it with the following content:

```sh
$ nano fulcrum/fulcrum.conf
```

```ini
# MobyBolt: fulcrum configuration
# /home/fulcrum/.fulcrum/fulcrum.conf

## Bitcoin Core settings
bitcoind = bitcoin:8332
rpccookie = /data/bitcoin/.cookie

## Admin Script settings
admin = 8000

## Fulcrum server general settings
datadir = /home/fulcrum/db
pidfile = /run/fulcrum/fulcrum.pid
tcp = 0.0.0.0:50001
peering = false

# Set utxo-cache according to your device,
# recommended: utxo-cache=1/2 x RAM available e.g: 4GB RAM -> dbcache=2048
utxo-cache = 4096

# Banner
banner = /home/fulcrum/.fulcrum/fulcrum-banner.txt
```

{:.warning}
Adjust the `utxo-cache` value according to your hardware.

### Prepare the docker compose file

Create the [docker compose file](https://qubitpi.github.io/docker-docs/compose/compose-yaml-file/){:target="_blank"} and populate it with the following content:

```sh
$ nano fulcrum/docker-compose.yml
```

```yaml
services:
  fulcrum:
    build:
      context: .
      args:
        FULCRUM_VERSION: ${FULCRUM_VERSION}
        FULCRUM_GUID: ${FULCRUM_GUID}
        BITCOIN_GUID: ${BITCOIN_GUID}
    container_name: ${COMPOSE_PROJECT_NAME}_fulcrum
    depends_on:
      bitcoin:
        condition: service_healthy
    expose:
      - "50001:50001"
    image: ${COMPOSE_PROJECT_NAME}/fulcrum:${FULCRUM_VERSION}
    networks:
      backend:
        ipv4_address: ${FULCRUM_ADDRESS}
    restart: unless-stopped
    stop_grace_period: 3m
    volumes:
      - fulcrum-data:/home/fulcrum/db/
      - bitcoin-data:/data/bitcoin/:ro
      - ./fulcrum.conf:/home/fulcrum/fulcrum.conf:ro

volumes:
  fulcrum-data:
```

In this file:
1. we `build` the Dockerfile and create an image named `mobybolt/fulcrum:v1.12.0`;
2. we define the `restart` policy of the container in case of failures;
3. we declare the bitcoin service as a dependency (Fulcrum will not run if bitcoin is not active);
4. we provide the container:
   1. with the previously defined configuration ([bind mount](https://docs.docker.com/storage/bind-mounts/){:target="_blank"});
   2. with the bitcoin volume data, from which it will reach the RPC authentication cookie;
   3. with a [volume](https://docs.docker.com/storage/volumes/){:target="_blank"} named `mobybolt_fulcrum-data` to store persistent data;
   4. with the `FULCRUM_ADDRESS` static address.

### Link the docker compose File

Link the fulcrum-specific docker compose file in the main one by running:

```sh
$ sed -i '/^networks:/i \ \ - fulcrum/docker-compose.yml' docker-compose.yml
```

The file should look like this:

```sh
$ cat docker-compose.yml
```

```yaml
include:
  - ...
  - fulcrum/docker-compose.yml
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

Let's build the fulcrum image by typing:

```sh
$ docker compose build fulcrum
```

Check for a new image called `mobybolt/fulcrum:v1.12.0`:

```sh
$ docker images | grep "fulcrum\|TAG"
> REPOSITORY          TAG        IMAGE ID       CREATED              SIZE
> mobybolt/fulcrum    v1.12.0    03c38d632c76   About a minute ago   345MB
```

---

## Run

Run the following command and check the output:

```sh
$ docker compose up -d fulcrum
> [+] Running 2/2
> ✔ Volume "mobybolt_fulcrum-data"  Created
> ✔ Container mobybolt_fulcrum      Started
```

Check the container logs:

```sh
$ docker compose logs fulcrum
> ...
> [2024-07-25 08:16:13.743] <Controller> Processed height: 1000, 0.1%, 88.4 blocks/sec, 90.1 txs/sec, 92.4 addrs/sec
> [2024-07-25 08:16:31.127] <Controller> Processed height: 2000, 0.2%, 57.5 blocks/sec, 58.2 txs/sec, 62.7 addrs/sec
> [2024-07-25 08:16:41.038] <Controller> Processed height: 3000, 0.4%, 100.9 blocks/sec, 102.9 txs/sec, 106.9 addrs/sec
> ...
```

Check the container status:

```sh
$ docker compose ps | grep "fulcrum\|NAME"
> NAME                IMAGE                      COMMAND                  SERVICE    CREATED          STATUS          PORTS
> mobybolt_fulcrum    mobybolt/fulcrum:v1.12.0   "Fulcrum /home/fulcr…"   fulcrum    48 minutes ago   Up 48 minutes   0/tcp                                                                                              mobybolt_fulcrum
```

{:.note}
>If not already present, docker will also create the `mobybolt_fulcrum-data` volume. You can check for it with the command:
>
>```sh
>$ docker volume ls | grep "fulcrum\|DRIVER"
>> DRIVER    VOLUME NAME
>> local     mobybolt_fulcrum-data
>```

---

## Fulcrum is syncing

Fulcrum must first fully index the blockchain and compact its database before you can connect to it with your wallets. This can take up to ~1.5 - 4 days or more, depending on the hardware. Only proceed with the [Blockchain explorer](blockchain-explorer) and [Desktop Wallet](desktop-wallet) sections once Fulcrum is ready.

Fulcrum will now index the whole Bitcoin blockchain so that it can provide all necessary information to wallets. With this, the wallets you use no longer need to connect to any third-party server to communicate with the Bitcoin peer-to-peer network.

{:.important}
>**DO NOT REBOOT OR STOP THE SERVICE DURING THE DB CREATION PROCESS. YOU MAY CORRUPT THE FILES**
>
>In case that happens, start the sync from scratch by deleting the `mobybolt_fulcrum-data volume`, following the next steps:
>
>- Remove Fulcrum container:
>  ```sh
>  $ docker compose down fulcrum
>  > [+] Running 2/1
>  > ✔ Container mobybolt_fulcrum  Removed
>  ```
>- Remove Fulcrum volume:
>  ```sh
>  $ docker volume rm mobybolt_fulcrum-data
>  > mobybolt_fulcrum-data
>  ```
>- Follow the [run](#run) section again.

When you see logs like this `SrvMgr: starting 3 services ...`, which means that Fulcrum is fully indexed

```log
[2024-06-09 10:28:56.705] SrvMgr: starting 3 services ...
[2024-06-09 10:28:56.706] Starting listener service for TcpSrv 0.0.0.0:50001 ...
[2024-06-09 10:28:56.706] Service started, listening for connections on 0.0.0.0:50001
[2024-06-09 10:28:56.706] Starting listener service for SslSrv 0.0.0.0:50002 ...
[2024-06-09 10:28:56.706] Service started, listening for connections on 0.0.0.0:50002
[2024-06-09 10:28:56.707] Starting listener service for AdminSrv 127.0.0.1:8000 ...
[2024-06-09 10:28:56.707] Service started, listening for connections on 127.0.0.1:8000
[2024-06-09 10:28:56.707] <Controller> Starting ZMQ Notifier (hashblock) ...
```

---

## Fulcrum Admin Script

Fulcrum comes with an admin script. The admin service, only available once Fulcrum is fully synchronized, is used for sending special control commands to the server. You may send commands to Fulcrum using this script.

Type the next command to see a list of possible subcommands that you can send to Fulcrum

```sh
$ docker compose exec fulcrum FulcrumAdmin -h
> usage: FulcrumAdmin [-h] -p port [-j] [-H [host]]
                  {addpeer,ban,banpeer,bitcoind_throttle...
> ...
```

Type the next command to get complete server information

```sh
$ docker compose exec fulcrum FulcrumAdmin -p 8000 getinfo
```

{:.hint}
Get more information about this command in the official documentation [section](https://github.com/cculianu/Fulcrum#admin-script-fulcrumadmin){:target="_blank"}

---

## Remote access over SSL/TLS

As [already mentioned](../setup/reverse-proxy), even though Fulcrum supports SSL/TLS connections, we'll still use nginx for these connections.

To perform this configuration:

- create the fulcrum-reverse-proxy configuration file with the following contents:

  ```sh
  $ nano nginx/streams-enabled/fulcrum-reverse-proxy.conf
  ```

  ```nginx
  upstream fulcrum {
    server 172.16.21.11:50001;
  }
  server {
    listen 50002 ssl;
    proxy_pass fulcrum;
  }
  ```

- test nginx configuration:

  ```sh
  $ docker exec mobybolt_nginx nginx -t
  > nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
  > nginx: configuration file /etc/nginx/nginx.conf test is successful
  ```

- Open the fulcrum port in the nginx docker compose:

  ```sh
  $ grep '^ *ports:' nginx/docker-compose.yml || sed -i '/restart:/i  \ \ \ \ ports:' nginx/docker-compose.yml
  $ sed -i '/restart:/i  \ \ \ \ \ \ \- 50002:50002 # fulcrum' nginx/docker-compose.yml
  ```
  
  The file should now look like this:

  ```sh
  $ cat nginx/docker-compose.yml
  > ...
  > image: ${COMPOSE_PROJECT_NAME}/nginx:${NGINX_VERSION}
  > ports:
  >   - "50002:50002" # fulcrum
  > restart: unless-stopped
  > ...
  ```

  This configuration will allow the Fulcrum ssl/tls port in the docker-managed firewall.

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
  > mobybolt_nginx   mobybolt/nginx:mainline   "/docker-entrypoint.…"   nginx      2 hours ago   Up 5 minutes (healthy)   80/tcp, 0.0.0.0:50002->50002/tcp, :::50002->50002/tcp
  ```

---

## Remote access over Tor

- Edit the tor configuration file, adding the following content at the end:

  ```sh
  $ nano tor/torrc
  ```

  ```conf
  # Hidden Service Fulcrum
  HiddenServiceDir /var/lib/tor/hidden_service_fulcrum/
  HiddenServiceVersion 3
  HiddenServicePoWDefensesEnabled 1
  HiddenServicePort 50001 172.16.21.11:50001
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
  $ docker compose exec tor cat /var/lib/tor/hidden_service_fulcrum/hostname
  > abcdefg..............xyz.onion
  ```

---

## Upgrade

{:.warning}
If your current version is less than v1.12.0, replace the Dockerfile with the one in this [section](#prepare-the-dockerfile).

Check the [Fulcrum release page](https://github.com/cculianu/Fulcrum/releases){:target="_blank"} for a new version and change the `FULCRUM_VERSION` value in the `.env` file.
Then, redo the steps described in:

1. [Build](#build)
2. [Run](#run)

If everything is ok, you can clear the old image and build cache, like in the following example:

```sh
$ docker images | grep "fulcrum\|TAG"
> REPOSITORY           TAG       IMAGE ID       CREATED          SIZE
> mobybolt/fulcrum     v1.12.0   03c38d632c76   3 minutes ago    345MB
> mobybolt/fulcrum     v1.11.1   3613ae3d3613   14 minutes ago   322MB
```

```sh
$ docker image rm mobybolt/fulcrum:v1.11.1
> Untagged: mobybolt/fulcrum:v1.11.1
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

Follow the next steps to uninstall fulcrum:

1. Unlink nginx:
   
   - remove fulcrum port:

     ```sh
     $ rm -f nginx/config/streams-enabled/fulcrum-reverse-proxy.conf
     $ sed -i '/50002:50002/d' nginx/docker-compose.yml
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
     > mobybolt_nginx   mobybolt/nginx:mainline   "/docker-entrypoint.…"   nginx      2 hours ago   Up 5 minutes (healthy)      80/tcp, 0.0.0.0:50002->50002/tcp, :::50002->50002/tcp
     ```

2. Unlink tor:

   - edit tor configuration and remove the following lines:

     ```sh
     $ nano tor/torrc
     ```
  
     ```conf
     # Hidden Service Fulcrum
     HiddenServiceDir /var/lib/tor/hidden_service_fulcrum/
     HiddenServiceVersion 3
     HiddenServicePoWDefensesEnabled 1
     HiddenServicePort 50001 172.16.21.11:50001
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
   $ docker compose down fulcrum
   > [+] Running 2/1
   > ✔ Container mobybolt_fulcrum  Removed
   > ...
   ```

4. Unlink the docker compose file:

   ```sh
   $ sed -i '/- fulcrum\/docker-compose.yml/d' docker-compose.yml
   ```

5. Remove the image:

   ```sh
   $ docker image rm $(docker images | grep fulcrum | awk '{print $3}')
   > Untagged: mobybolt/fulcrum:v1.12.0
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
   $ docker volume rm mobybolt_fulcrum-data
   > mobybolt_fulcrum-data
   ```

8. Remove files and directories (optional):

   ```sh
   $ rm -rf fulcrum
   ```

9. Cleanup the env (optional)

   ```sh
   $ sed -i '/^FULCRUM_/d' .env
   ```

---

{:.d-flex .flex-justify-between}
[<< Bitcoin client](bitcoin-client)
[Blockchain explorer >>](blockchain-explorer)