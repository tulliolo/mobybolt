---
layout: default
title: Blockchain explorer
nav_order: 30
parent: + Bitcoin
grand_parent: MobyBolt
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Blockchain explorer
{:.no_toc}

{: .text-center}
![blockchain explorer logo](../../../images/mobybolt-bitcoin-blockchain-explorer_logo.svg){: width="15%"}

Run your own private blockchain explorer with [BTC RPC Explorer](https://github.com/janoside/btc-rpc-explorer){:target="_blank"}. Trust your node, not some external services.

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

## Run your own blockchain explorer

After the MobyBolt runs your own fully validated node, and even acts as a backend for your hardware wallet with an [Electrum server](electrum-server), the last important puzzle piece to improve privacy and financial sovereignty is your own Blockchain Explorer. It lets you query transactions, addresses, and blocks of your choice. You no longer need to leak information by querying a third-party blockchain explorer that can be used to get your location and cluster addresses.

[BTC RPC Explorer](https://github.com/janoside/btc-rpc-explorer){:target="_blank"} provides a lightweight and easy to use web interface to accomplish just that. It's a database-free, self-hosted Bitcoin blockchain explorer, querying the [Bitcoin client](bitcoin-client) and the [Electrum server](electrum-server) via RPC.

---

## Prepare

Create the BTC RPC Explorer directory:

```sh
$ mkdir btcrpcexplorer
```

### Prepare the environment

Edit the `.env` file and append the following content to the end:

```sh
$ nano .env
```

```ini
# BTC RPC Explorer
BTCEXP_VERSION=v3.5.0
BTCEXP_ADDRESS=172.16.21.12
BTCEXP_GUID=1102
```

In this file:
1. we define the `BTCEXP_VERSION` (check the latest available version [here](https://github.com/janoside/btc-rpc-explorer/releases){:target="_blank"});
2. we define a static address for the container;
3. we define the `guid` (group and user id) of the explorer user.

### Prepare the Dockerfile

Create the [Dockerfile](https://docs.docker.com/reference/dockerfile/){:target="_blank"} and populate it with the following content:

```sh
$ nano btcrpcexplorer/Dockerfile
```

```Dockerfile
# base image
ARG NODE_VERSION=24
FROM node:$NODE_VERSION AS base

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
      curl \
      git && \
    rm -rf /var/lib/apt/lists/*


# builder image
FROM base AS builder

ARG BTCEXP_VERSION

ENV BTCEXP_GIT_URL="https://github.com/janoside/btc-rpc-explorer.git" \
    BTCEXP_SIG_URL="https://github.com/janoside.gpg"

# import signatures and clone repository
RUN set -eux && \
    curl $BTCEXP_SIG_URL | gpg --import && \
    git clone --branch $BTCEXP_VERSION $BTCEXP_GIT_URL

WORKDIR /btc-rpc-explorer

RUN set -eux && \
    # check signatures
    #git verify-commit $BTCEXP_VERSION && \
    # install btcrpcexplorer
    npm install

    
# result image
FROM node:$NODE_VERSION

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y curl && \
    rm -rf /var/lib/apt/lists/*

# default uid for btcrpcexplorer user
ARG BTCEXP_GUID=1102

ARG BITCOIN_GUID=1100

RUN set -xe && \
    # set node user and group guid
    groupmod -g $BTCEXP_GUID node && \
    usermod -u $BTCEXP_GUID node && \
    # create bitcoin group and add node user to bitcoin group
    addgroup --gid $BITCOIN_GUID bitcoin && \
    adduser node bitcoin

# copy app
COPY --from=builder --chown=node:node /btc-rpc-explorer/ /home/node/

# switch user
USER node
WORKDIR /home/node
ENTRYPOINT ["npm", "start"]
```

In this file:
1. we define a builder image (`builder`, based on the official [node](https://hub.docker.com/_/node/){:target="_blank"} image) to buid BTC RPC Explorer from github sources, verifying version tag signatures;
2. we define a result image:
   1. installing some needed dependencies;
   2. copying binaries from builder image;
   3. configuring the `node` user and the directories to which he will have access;
   4. adding the `node` user to the `bitcoin` group for RPC cookie authentication.

### Configure BTC RPC Explorer

Create the BTC RPC Explorer env file and populate it with the following content:

```sh
$ nano btcrpcexplorer/btcrpcexplorer.env
```

```ini
# Optional logging settings, uncomment one of these example lines or add your own.
# See comments after each for more info.
# Default: "btcexp:app,btcexp:error"
#DEBUG=*  # Enable all logging, including middleware
#DEBUG=btcexp:*  # Enable all logging specific to btc-rpc-explorer
#DEBUG=btcexp:app,btcexp:error  # Default


# The base URL. If you want to run it elsewhere than on /, for example /btc-rpc-explorer/ - note that the value should include starting and ending "/"
# Default: /
#BTCEXP_BASEURL=/
#BTCEXP_BASEURL=/explorer/



# Whether your site will be served via HTTPS (impacts session cookies)
# Note: if true, the express app will also have "trust proxy" set to 1, to help anyone running this tool behind a HTTPS reverse proxy
# Default: false
#BTCEXP_SECURE_SITE=false


# The active coin. Only officially supported value is "BTC".
# Default: BTC
#BTCEXP_COIN=BTC


# Host/Port to bind to
# Defaults: shown
BTCEXP_HOST=0.0.0.0
BTCEXP_PORT=3002


# Bitcoin RPC Credentials (URI -OR- HOST/PORT/USER/PASS)
# Defaults:
#   - [host/port]: 127.0.0.1:8332
#   - [username/password]: none
#   - cookie: '~/.bitcoin/.cookie'
#   - timeout: 5000 (ms)
#BTCEXP_BITCOIND_URI=bitcoin://rpcusername:rpcpassword@127.0.0.1:8332?timeout=10000
BTCEXP_BITCOIND_HOST=bitcoin
BTCEXP_BITCOIND_PORT=8332
#BTCEXP_BITCOIND_USER=rpcusername
#BTCEXP_BITCOIND_PASS=rpcpassword
BTCEXP_BITCOIND_COOKIE=/data/bitcoin/.cookie
#BTCEXP_BITCOIND_RPC_TIMEOUT=5000


# Select optional "address API" to display address tx lists and balances
# Options: electrum, electrumx, blockchain.com, blockchair.com, blockcypher.com
#
# If this value is set to electrum (or the old value "electrumx"), then
# BTCEXP_ELECTRUM_SERVERS must also be set
#
# Default: none
BTCEXP_ADDRESS_API=electrum


# Optional Electrum Protocol Servers. See BTCEXP_ADDRESS_API. This value is only
# used if BTCEXP_ADDRESS_API=electrum (or the old value "electrumx")
# 
# This variable was formerly named BTCEXP_ELECTRUMX_SERVERS and that name still works.
#
# Default: none
BTCEXP_ELECTRUM_SERVERS=tcp://fulcrum:50001


# Whether to use the Electrum server as an external txindex.
# This is only available in the Electrs implementation. Electrs txindex can serve as a
# full replacement for the Bitcoin Core txindex, but Bitcoin Core's implementation
# is likely faster.
#BTCEXP_ELECTRUM_TXINDEX=true


# Set number of concurrent RPC requests. Should be lower than your node's "rpcworkqueue" value.
# Note that Bitcoin Core's default rpcworkqueue=16.
# Default: 10
#BTCEXP_RPC_CONCURRENCY=10


# Disable app's in-memory RPC caching to reduce memory usage
# Default: false (i.e. in-memory cache **enabled**)
#BTCEXP_NO_INMEMORY_RPC_CACHE=true


# Optional redis server for RPC caching
# Default: none
#BTCEXP_REDIS_URL=redis://localhost:6379


# Default: hash of credentials
#BTCEXP_COOKIE_SECRET=0000aaaafffffgggggg


# Whether public-demo aspects of the site are active
# Default: false
#BTCEXP_DEMO=true


# Set to false to enable resource-intensive features, including:
# UTXO set summary querying
# (default value is true, i.e. resource-intensive features are disabled)
BTCEXP_SLOW_DEVICE_MODE=false


# Privacy mode disables:
# Exchange-rate queries, IP-geolocation queries
# Default: false
BTCEXP_PRIVACY_MODE=true


# Don't request currency exchange rates
# Default: true (i.e. no exchange-rate queries made)
BTCEXP_NO_RATES=true


# Password protection for site via basic auth (enter any username, only the password is checked)
# Default: none
#BTCEXP_BASIC_AUTH_PASSWORD=mypassword


# File where the SSO token is stored; ignored if BTCEXP_BASIC_AUTH_PASSWORD is provided.
# Enables SSO if present.
# Default: none
#BTCEXP_SSO_TOKEN_FILE=/var/run/btc-rpc-explorer/sso_token


# URL of an optional external SSO provider
# This is ignored if SSO is not enabled (see BTCEXP_SSO_TOKEN_FILE)
# Default: none
#BTCEXP_SSO_LOGIN_REDIRECT_URL=/my-sso-provider/login


# Enable to allow access to all RPC methods
# Default: false
#BTCEXP_RPC_ALLOWALL=true


# Custom RPC method blacklist
# Default: (see config.js)
#BTCEXP_RPC_BLACKLIST=signrawtransaction,sendtoaddress,stop,...


# Optional API keys
# Default: none
#BTCEXP_GANALYTICS_TRACKING=UA-XXXX-X
#BTCEXP_SENTRY_URL=https://00000fffffff@sentry.io/XXXX
#BTCEXP_IPSTACK_APIKEY=000000fffffaaaaa
#BTCEXP_MAPBOX_APIKEY=000000fffffaaaaa


# Optional value for a directory for filesystem caching
# Default: ./cache
#BTCEXP_FILESYSTEM_CACHE_DIR=./cache


# Optional analytics
#BTCEXP_PLAUSIBLE_ANALYTICS_DOMAIN=domain.com
#BTCEXP_PLAUSIBLE_ANALYTICS_SCRIPT_URL=https://url-to/plausible.js


# Optional value for "max_old_space_size"
# Default: 1024
#BTCEXP_OLD_SPACE_MAX_SIZE=2048


# The number of recent blocks to search for transactions when txindex is disabled
#BTCEXP_NOTXINDEX_SEARCH_DEPTH=3



# Display Currency
# Default: btc
#BTCEXP_DISPLAY_CURRENCY=(btc|sat|local)

# Local Currency
# Default: usd
#BTCEXP_LOCAL_CURRENCY=(usd|eur|...)

# UI Timezone
# Default: utc
#BTCEXP_UI_TIMEZONE=(utc|local)

# UI Theme
# Default: dark
#BTCEXP_UI_THEME=(dark|light)

# UI Option: Hide info notes
# Default: false
#BTCEXP_UI_HIDE_INFO_NOTES=(true|false)



# Set the number of recent blocks shown on the homepage.
# For slow devices reduce this number.
# Default: 10
#BTCEXP_UI_HOME_PAGE_LATEST_BLOCKS_COUNT=10


# Set the number of blocks per page on the browse-blocks page.
# For slow devices reduce this number.
# Default: 50
#BTCEXP_UI_BLOCKS_PAGE_BLOCK_COUNT=50



#########


# Options designed for production use, on public instances like the one at BitcoinExplorer.org.

# S3 details for uploading assets to be served via CloudFront

# This is the optional profile name that the AWS SDK will use to load credentials. By default this refers to an item in ~/.aws/credentials
#AWS_PROFILE=xxx

# The S3 bucket where assets will be uploaded on launch
#BTCEXP_S3_BUCKET=xxx

# The region that the above S3 bucket exists
#BTCEXP_S3_BUCKET_REGION=xxx

# The path in the above S3 bucket where assets will be uploaded on launch
#BTCEXP_S3_BUCKET_PATH=xxx/

# CDN base url; if S3 details are given, this will probably be a CloudFront path for assets that are uploaded at launch
#BTCEXP_CDN_BASE_URL=xxx
```

In this file we define the environment variables used for the configuration of BTC RPC Explorer. In particular:

1. we instruct BTC RPC Explorer to connect to the Bitcoin client:

   ```ini
   BTCEXP_BITCOIND_HOST=bitcoin
   BTCEXP_BITCOIND_PORT=8332
   BTCEXP_BITCOIND_COOKIE=/data/bitcoin/.cookie   
   ```

2. we instruct BTC RPC Explorer to connect to the Electrum server to get address balances:

   ```ini
   BTCEXP_ADDRESS_API=electrum
   BTCEXP_ELECTRUM_SERVERS=tcp://fulcrum:50001   
   ```

3. we optimize the configuration for more privacy (no external queries):

   ```ini
   BTCEXP_PRIVACY_MODE=true
   BTCEXP_NO_RATES=true
   ```
   
   {:.note}
   >if you prioritize the amount of information over privacy, you can change both parameters to `false`, but you'll also need to enable the `frontend` network in the docker compose file.
   >
   >{:.text-center .text-red-000}
   >**Please note that all external queries will be in clearnet and will not use tor**

### Prepare the Docker Compose file

Create the [Docker Compose file](https://qubitpi.github.io/docker-docs/compose/compose-yaml-file/){:target="_blank"} and populate it with the following contents:

```sh
$ nano btcrpcexplorer/docker-compose.yml
```

```yaml
services:
  btcrpcexplorer:
    build:
      context: .
      args:
        BTCEXP_VERSION: ${BTCEXP_VERSION}
        BTCEXP_GUID: ${BTCEXP_GUID}
        BITCOIN_GUID: ${BITCOIN_GUID}
    container_name: ${COMPOSE_PROJECT_NAME}_btcrpcexplorer
    depends_on:
      - fulcrum
    expose:
      - "3002"
    healthcheck:
      test: ["CMD-SHELL", "curl -fk http://localhost:3002 >/dev/null || exit 1"]
      interval: 1m
      timeout: 10s
      retries: 3
    image: ${COMPOSE_PROJECT_NAME}/btcrpcexplorer:${BTCEXP_VERSION}
    networks:
      #frontend:
      backend:
        ipv4_address: ${BTCEXP_ADDRESS}
    restart: unless-stopped
    volumes:
      - ./btcrpcexplorer.env:/home/node/.env
      - bitcoin-data:/data/bitcoin/:ro

volumes:
  btcrpcexplorer-conf:
```

In this file:
1. we `build` the Dockerfile and create an image named `mobybolt/btcrpcexplorer:v3.5.0`;
2. we define the `restart` policy of the container in case of failures;
3. we define a HealthCheck task that polls the server every minute;
4. we declare the bitcoin service as a dependency (BTC RPC Explorer will not run if bitcoin is not active);
5. we provide the container:
   1. with the previously defined configuration ([bind mount](https://docs.docker.com/storage/bind-mounts/){:target="_blank"});
   2. with the bitcoin volume data, from which it will reach the RPC authentication cookie;
   3. with the `BTCEXP_ADDRESS` static address.

{:.note}
>if you prioritize the amount of information over privacy, you can uncomment the `#frontend` line in the docker compose file.
>
>{:.text-center .text-red-000}
>**Please note that all external queries will be in clearnet and will not use tor**

### Link the docker compose File

Link the explorer-specific docker compose file in the main one by running:

```sh
$ sed -i '/^networks:/i \ \ - btcrpcexplorer/docker-compose.yml' docker-compose.yml
```

The file should look like this:

```sh
$ cat docker-compose.yml
```

```yaml
include:
  - ...
  - btcrpcexplorer/docker-compose.yml
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

Let's build the BTC RPC Explorer image by typing:

```sh
$ docker compose build btcrpcexplorer
```

Check for a new image called `mobybolt/btcrpcexplorer:v3.5.0`:

```sh
$ docker images | grep "btcrpcexplorer\|TAG"
> REPOSITORY                TAG      IMAGE ID       CREATED        SIZE
> mobybolt/btcrpcexplorer   v3.4.0   fe31f5c849c2   5 months ago   1.26GB
```

---

## Run

Run the following command and check the output:

```sh
$ docker compose up -d btcrpcexplorer
> [+] Running 2/2
> ✔ Container mobybolt_btcrpcexplorer      Started
```

Check the container logs:

```sh
$ docker compose logs btcrpcexplorer
> > btc-rpc-explorer@3.4.0 start
> > node ./bin/www
>
> 2024-09-27T10:37:56.760Z btcexp:app Searching for config files...
> 2024-09-27T10:37:56.761Z btcexp:app Config file not found at /home/node/.config/btc-rpc-explorer.env, continuing...
> 2024-09-27T10:37:56.761Z btcexp:app Config file not found at /etc/btc-rpc-explorer/.env, continuing...
> 2024-09-27T10:37:56.761Z btcexp:app Config file found at /home/node/.env, loading...
> ...
```

Check the container status:

```sh
$ docker compose ps | grep "btcrpcexplorer\|NAME"
> NAME                      IMAGE                            COMMAND       SERVICE         CREATED         STATUS                   PORTS
> mobybolt_btcrpcexplorer   mobybolt/btcrpcexplorer:v3.4.0   "npm start"   btcrpcexplore   3 minutes ago   Up 3 minutes (healthy)   3002/tcp                                                                                           mobybolt_btcrpcexplorer
```

{:.warning}
>The `STATUS` of the previous command must be `(healthy)`, or `(health: starting)`. Any other status is incorrect.
>
>If the container is in `(health: starting)` status, wait a few minutes and repeat the above command until the status changes to `(healthy)`. If this does not happen, the run has failed.

---

## Remote access over HTTPS

In the docker compose file we have not opened ports for BTC RPC Explorer. To reach the web interface in https, we need to configure nginx as follows:

- create the btcrpcexplorer-reverse-proxy configuration file with the following contents:

  ```sh
  $ nano nginx/config/sites-enabled/btcrpcexplorer-reverse-proxy.conf
  ```

  ```nginx
  upstream btcrpcexplorer {
    server 172.16.21.12:3002;
  }
  server {
    listen 4000 ssl;
    proxy_pass btcrpcexplorer;
  }
  ```

- test nginx configuration:

  ```sh
  $ docker compose exec nginx nginx -t
  > nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
  > nginx: configuration file /etc/nginx/nginx.conf test is successful
  ```

- Open the BTC RPC Explorer port in the nginx docker compose:

  ```sh
  $ grep '^ *ports:' nginx/docker-compose.yml || sed -i '/restart:/i  \ \ \ \ ports:' nginx/docker-compose.yml
  $ sed -i '/restart:/i  \ \ \ \ \ \ \- "4000:4000"   # btcrpcexplorer' nginx/docker-compose.yml
  ```
  
  The file should now look like this:

  ```sh
  $ cat nginx/docker-compose.yml
  > ...
  > image: ${COMPOSE_PROJECT_NAME}/nginx:${NGINX_VERSION}
  > ports:
  >   - ...
  >   - "4000:4000"   # btcrpcexplorer
  > restart: unless-stopped
  > ...
  ```

  This configuration will allow the BTC RPC Explorer https port in the docker-managed firewall.

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
  > mobybolt_nginx   mobybolt/nginx:mainline   "/docker-entrypoint.…"   nginx      2 hours ago   Up 5 minutes (healthy)   0.0.0.0:4000->4000/tcp, :::4000->4000/tcp, 0.0.0.0:50002->50002/tcp, :::50002->50002/tcp
  ```

Try connecting from a PC browser on your local network at [https://mobybolt.local:4000](https://mobybolt.local:4000){:target="_blank"}:

![BTC RPC Explorer](../../../images/mobybolt-bitcoin-bitcoin-blockchain-explorer_screenshot.png)

---

## Remote access over Tor

- Edit the tor configuration file, adding the following content at the end:

  ```sh
  $ nano tor/torrc
  ```

  ```conf
  ## Hidden Service BTC RPC Explorer
  HiddenServiceDir /var/lib/tor/hidden_service_btcrpcexplorer/
  HiddenServiceVersion 3
  HiddenServicePoWDefensesEnabled 1
  HiddenServicePort 80 172.16.21.6:3002
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
  > mobybolt_tor   mobybolt/tor:0.4.8.16   "docker-entrypoint.sh"   tor        3 hours ago   Up About a minute (healthy)   9050-9051/tcp
  ```

- get your onion address:

  ```sh
  $ docker compose exec tor cat /var/lib/tor/hidden_service_btcrpcexplorer/hostname
  > abcdefg..............xyz.onion
  ```

Try connecting from Tor Browser (using your onion address above) at http://abcdefg..............xyz.onion.

---
  
## Upgrade

- Check the [BTC RPC Explorer release page](https://github.com/janoside/btc-rpc-explorer/releases){:target="_blank"} for a new version and change the `BTCEXP_VERSION` value in the `.env` file.
- Open the `btprpcexplorer/Dockerfile` and change the NODE_VERSION to 24: `ARG NODE_VERSION=24`.

Then, redo the steps described in:

1. [Build](#build)
2. [Run](#run)

If everything is ok, you can clear the old image and build cache, like in the following example:

```sh
$ docker images | grep "btcrpcexplorer\|TAG"
> REPOSITORY                TAG      IMAGE ID       CREATED          SIZE
> mobybolt/btcrpcexplorer   v3.5.0   03c38d632c76   3 minutes ago    1.26GB
> mobybolt/btcrpcexplorer   v3.4.0   3613ae3d3613   14 minutes ago   1.24GB
```

```sh
$ docker image rm mobybolt/btcrpcexplorer:v3.3.0
> Untagged: mobybolt/btcrpcexplorer:v3.4.0
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

Follow the next steps to uninstall BTC RPC Explorer:

1. Unlink nginx:
   
   - remove fulcrum port:

     ```sh
     $ rm -f nginx/config/streams-enabled/btcrpcexplorer-reverse-proxy.conf
     $ sed -i '/4000:4000/d' nginx/docker-compose.yml
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
     ## Hidden Service BTC RPC Explorer
     HiddenServiceDir /var/lib/tor/hidden_service_btcrpcexplorer/
     HiddenServiceVersion 3
     HiddenServicePoWDefensesEnabled 1
     HiddenServicePort 80 172.16.21.6:3002
     ```

   - restart tor:

     ```sh
     $ docker compose restart tor
     ```

   - check the tor container status (it should be `healthy`, if not repeat the command):
   
     ```sh
     $ docker compose ps | grep "tor\|NAME"
     > NAME           IMAGE                   COMMAND                   SERVICE    CREATED       STATUS                      PORTS
     > mobybolt_tor   mobybolt/tor:0.4.8.16   "/docker-entrypoint.sh"   tor        2 hours ago   Up 5 minutes (healthy)      9050-9051/tcp
     ```

3. Remove the container:

   ```sh
   $ docker compose down btcrpcexplorer
   > [+] Running 2/1
   > ✔ Container mobybolt_btcrpcexplorer  Removed
   > ...
   ```

4. Unlink the docker compose file:

   ```sh
   $ sed -i '/- btcrpcexplorer\/docker-compose.yml/d' docker-compose.yml
   ```

5. Remove the image:

   ```sh
   $ docker image rm $(docker images | grep btcrpcexplorer | awk '{print $3}')
   > Untagged: mobybolt/btcrpcexplorer:v3.5.0
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

7. Remove files and directories (optional):

   ```sh
   $ rm -rf btcrpcexplorer
   ```

8. Cleanup the env (optional)

   ```sh
   $ sed -i '/^BTCEXP_/d' .env
   ```

---

{:.d-flex .flex-justify-between}
[<< Electrum server](electrum-server)
[Desktop wallet >>](desktop-wallet)