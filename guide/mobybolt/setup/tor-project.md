---
layout: default
title: Tor project
nav_order: 30
parent: + Setup
grand_parent: MobyBolt
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Tor project
{:.no_toc}

{:.text-center}
![tor logo](../../../images/mobybolt-setup-tor-project_logo.png){:width="30%"}

Running your own Bitcoin and Lightning node at home makes you a direct, sovereign peer on the Bitcoin network.
However, if not configured without privacy in mind, it also tells the world that there is someone with Bitcoin at that address.

True, it's only your IP address that is revealed, but using services like [iplocation.net](https://www.iplocation.net){:target="_blank"}, your physical address can be determined quite accurately.
Especially with Lightning, your IP address would be widely used.
We need to make sure that you keep your privacy.

We'll also make it easy to connect to your node from outside your home network as an added benefit.

We use Tor, a free software built by the [Tor Project](https://www.torproject.org/){:target="_blank"}. It allows you to anonymize internet traffic by routing it through a network of nodes, hiding your location and usage profile.

It is called "Tor" for "The Onion Router": information is routed through many hops and encrypted multiple times. Each node decrypts only the layer of information addressed to it, learning only the previous and the next hop of the whole route. The data package is peeled like an onion until it reaches the final destination.

The Tor network also hosts hidden services, which can be reached via an "onion" address.

---

To follow this section, log in to your node as `satoshi` user via Secure Shell (SSH) and access the project's home:

```sh
$ cd $HOME/apps/mobybolt
```

---

## Table of contents
{:.no_toc .text-delta}

1. TOC
{:toc}

---

## Prepare

Let's create the directory structure for tor:

```sh
$ mkdir tor
```

### Prepare the environment

Edit the `.env` file and append the following content to the end:

```sh
$ nano .env
```

```conf
# tor
TOR_VERSION=0.4.8.13
TOR_ADDRESS=172.16.21.3
TOR_GUID=102
```

In this file:
1. we define the `TOR_VERSION` (check the latest available version [here](https://www.torproject.org/download/tor/){:target="_blank"});
2. we define a static address for the container's backend network;
3. we define the `guid` (group and user id) of the tor user.

### Prepare the entrypoint

Create the [entrypoint](https://docs.docker.com/reference/dockerfile/#entrypoint){:target="_blank"} (the script to run when the container starts) and populate it with the following contents:

```sh
$ nano tor/docker-entrypoint.sh
```

```bash
#!/bin/bash
set -eu

CONF_FILE=/etc/tor/torrc
DATA_DIR=/var/lib/tor/
PID_FILE=/run/tor/tor.pid

init_config () { 
  cat > $CONF_FILE <<EOF
SocksPort 0.0.0.0:9050
DataDirectory $DATA_DIR
PidFile $PID_FILE
EOF
}

if ! [[ -f $CONF_FILE ]]; then
  init_config
fi

CMD=$@
if [[ $# -eq 0 ]]; then
  # missing parameters, run tor
  CMD=tor
  CMD="$CMD -f $CONF_FILE"
  $CMD --verify-config
fi

exec $CMD
```

In this file:
1. we create a default configuration for tor;
2. we define the default files and directories;
3. we run tor.

### Prepare the Dockerfile

Create the [Dockerfile](https://docs.docker.com/reference/dockerfile/){:target="_blank"} and populate it with the following contents:

```sh
$ nano tor/Dockerfile
```

```Dockerfile
# base image
FROM debian:stable-slim AS base

RUN set -eux && \
    # install dependencies
    apt update && \
    apt install -y \
        build-essential \
        ccache \
        curl \
        gpg \
        gpg-agent \
        libcap-dev \
        libevent-dev \
        liblzma-dev \
        libseccomp-dev \
        libssl-dev \
        libzstd-dev \
        pkgconf \
        shellcheck \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*


# builder image
FROM base AS builder

ARG TOR_VERSION

ENV TOR_KEYS="514102454D0A87DB0767A1EBBE6A0531C18A9179 B74417EDDF22AC9F9E90F49142E86A2A11F48D36 7A02B3521DC75C542BA015456AFEE6D49E92B601"
ENV TOR_URL="https://dist.torproject.org"

# download source, checksum and signatures
ADD $TOR_URL/tor-$TOR_VERSION.tar.gz $TOR_URL/tor-$TOR_VERSION.tar.gz.sha256sum $TOR_URL/tor-$TOR_VERSION.tar.gz.sha256sum.asc .

RUN set -eux && \
    # verify source
    gpg --keyserver keyserver.ubuntu.com --recv-keys $TOR_KEYS && \
    gpg --verify tor-$TOR_VERSION.tar.gz.sha256sum.asc && \
    sha256sum -c tor-$TOR_VERSION.tar.gz.sha256sum && \
    # extract source
    tar -xzf "/tor-$TOR_VERSION.tar.gz"
    
WORKDIR /tor-$TOR_VERSION/

RUN set -eux && \
    # build tor
    ./configure --disable-asciidoc --disable-html-manual --disable-manpage --enable-gpl --enable-lzma --enable-zstd --datadir=/var/lib --sysconfdir=/etc && \
    make -j$(nproc) && \
    make -j$(nproc) check && \
    make install


# result image
FROM debian:stable-slim

RUN set -eux && \
    # install dependencies
    apt update && \
    apt install -y \
        curl \
        libevent-dev \
        liblzma5 \
        libzstd1 \
        openssl \
        zlib1g && \
    rm -rf /var/lib/apt/lists/*

# setup tor user and dirs
ARG TOR_GUID=102

RUN set -eux && \
    addgroup --gid $TOR_GUID tor && \
    adduser --system --comment "" --gid $TOR_GUID --home /var/lib/tor/ --uid $TOR_GUID tor && \
    mkdir /etc/tor/ && \
    mkdir -m 0700 /run/tor/ && \
    chown -R tor:tor /etc/tor/ /run/tor/

# copy tor files
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder --chown=tor:tor /var/lib/tor/ /var/lib/tor/

COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/

# set user and entrypoint
USER tor
ENTRYPOINT ["docker-entrypoint.sh"]
```

In this file:
1. we define a `builder` image to buid tor from github sources, verifying version tag signatures;
2. we define a `result` image:
   1. installing curl (for healthcheck purposes) and other needed dependencies;
   2. copying binaries from the builder image;
   3. configuring the `tor` user and the directories it will have access to;
   4. setting the `entrypoint` [previously](#prepare-the-entrypoint) created.

### Configure Tor

Create the tor configuration file and populate it with the following contents:

```sh
$ nano tor/torrc
```

```conf
SocksPort 0.0.0.0:9050

DataDirectory /var/lib/tor/
DataDirectoryGroupReadable 1

ControlPort 0.0.0.0:9051
CookieAuthentication 1
CookieAuthFile /var/lib/tor/control_auth_cookie
CookieAuthFileGroupReadable 1

PidFile /run/tor/tor.pid

############### This section is just for location-hidden services ###

## Once you have configured a hidden service, you can look at the
## contents of the file ".../hidden_service/hostname" for the address
## to tell people.
##
## HiddenServicePort x y:z says to redirect requests on port x to the
## address y:z.

```

### Prepare the docker-compose file

Create a tor-specific docker-compose file and populate it with the following contents:

```sh
$ nano tor/docker-compose.yml
```

```yaml
services:
  tor:
    build:
      context: .
      args:
        TOR_VERSION: ${TOR_VERSION}
        TOR_GUID: ${TOR_GUID}
    container_name: ${COMPOSE_PROJECT_NAME}_tor
    expose:
      - "9050"
      - "9051"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD-SHELL", "curl -f -x socks5h://localhost:9050 -s https://check.torproject.org/api/ip || exit 1"]
      interval: 180s
      timeout: 10s
      retries: 3
      start_period: 60s
    image: ${COMPOSE_PROJECT_NAME}/tor:${TOR_VERSION}
    networks:
      frontend:
      backend:
        ipv4_address: ${TOR_ADDRESS}
    restart: unless-stopped
    stop_grace_period: 60s
    volumes:
      - ./torrc:/etc/tor/torrc:ro
      - tor-data:/var/lib/tor/
  
volumes:
  tor-data:
```

{:.warning}
Be very careful to respect the indentation above, since yaml is very sensitive to this!

In this file:

1. we `build` the Dockerfile and create an image named `mobybolt/tor:${TOR_VERSION}`;

2. we define a `healthcheck` that will check every 3 minutes that the exit IP address is a tor address; 
   1. after three failed attempts, the container will be marked `unhealthy`;

3. we attach the container to the `backend` and `frontend` `networks`:
   1. we provide the container with the `TOR_ADDRESS` static address in the backend network;
   2. the tor proxy will receive connection requests from the tor network and redirect them to the affected services via the backend network;
   3. the tor proxy will receive connection requests in the backend network and redirect them to tor network;

4. we define the `restart` policy `unless-stopped` for the container: this way, the container will always be automatically restarted, unless it has been stopped explicitly.

5. we provide the container with the previously defined configuration ([bind mount](https://docs.docker.com/storage/bind-mounts/){:target="_blank"}) and with a [volume](https://docs.docker.com/storage/volumes/){:target="_blank"} named `mobybolt_tor-data` to store persistent data.

### Link the docker-compose File

Edit the main docker-compose file and link the tor-specific one in the `include` section:

```sh
$ nano docker-compose.yml
```

The file should look like this:

```yaml
include:
  - ...
  - tor/docker-compose.yml
```

{:.warning}
Be very careful to respect the indentation above, since yaml is very sensitive to this!

### Test the docker-compose File

Run the following command and check the output:

```sh
$ docker compose config --quiet && printf "OK\n" || printf "ERROR\n"
> OK
```

{:.hint}
If the output is `ERROR`, check the error reported... Maybe some wrong indentation in the yaml files?

---

## Build

Let's build the tor image by typing:

```sh
$ docker compose build tor
```

{:.warning}
This may take a long time.

Check for a new image called `mobybolt/tor:0.4.8.13`:

```sh
$ docker images | grep "tor\|TAG"
> REPOSITORY       TAG        IMAGE ID       CREATED              SIZE
> mobybolt/tor     0.4.8.13   dc4f7683b05f   About a minute ago   130MB
```

---

## Run

Run the following command and check the output:

```sh
$ docker compose up -d tor
> [+] Running 2/2
> ✔ Volume "mobybolt_tor-data"  Created
> ✔ Container mobybolt_tor      Started
```

Check the container logs:

```sh
$ docker compose logs tor
> ...
> May 09 10:14:13.000 [notice] Bootstrapped 95% (circuit_create): Establishing a Tor circuit
> May 09 10:14:14.000 [notice] Bootstrapped 100% (done): Done
> ...
```

Check the container status:

```sh
$ docker compose ps | grep "tor\|NAME"
> NAME           IMAGE                   COMMAND                  SERVICE   CREATED              STATUS                                 PORTS
> mobybolt_tor   mobybolt/tor:0.4.8.13   "docker-entrypoint.sh"   tor       About a minute ago   Up About a minute (health: starting)   9050-9051/tcp
```

{:.warning}
>The `STATUS` of the previous command must be `(healthy)`, or `(health: starting)`. Any other status is incorrect.
>
>If the container is in `(health: starting)` status, wait a few minutes and repeat the above command until the status changes to `(healthy)`. If this does not happen, the run has failed.

{:.note}
>If not already present, docker will also create the `mobybolt_tor-data` volume. You can check for it with the command:
>
>```sh
>$ docker volume ls | grep "tor\|DRIVER"
>> DRIVER    VOLUME NAME
>> local     mobybolt_tor-data
>```

---

## SSH remote access through Tor (optional)

If you want to log into your MobyBolt with SSH when you're away, you can easily do so by adding a Tor hidden service.
This makes "calling home" very easy, without the need to configure anything on your internet router.

### SSH server

- Add the following lines at the end of the `torrc` file:
Save and exit

  ```sh
  $ nano tor/torrc
  ```

  ```conf
  # Hidden Service SSH server
  HiddenServiceDir /var/lib/tor/hidden_service_sshd/
  HiddenServiceVersion 3
  HiddenServicePoWDefensesEnabled 1
  HiddenServicePort 22 host.docker.internal:22

  ```

- Check the new configuration:

  ```sh
  $ docker compose exec -it tor tor --verify-config
  > ...
  > Configuration was valid
  ```

- Restart Tor container:

  ```sh
  $ docker compose restart tor
  >[+] Restarting 1/1
  > ✔ Container mobybolt_tor  Started
  ```

- Look up your Tor connection address:
  
  ```sh  
  $ docker compose exec -it tor cat /var/lib/tor/hidden_service_sshd/hostname
  > abcdefg..............xyz.onion
  ```
  
  {:.hint}
  Save the Tor address in a secure location, e.g., your password manager.

### SSH client

You also need to have Tor installed on your regular computer where you start the SSH connection.
Usage of SSH over Tor differs by client and operating system.

A few examples:

- **Windows**: configure PuTTY as described in this guide [Torifying PuTTY](https://gitlab.torproject.org/legacy/trac/-/wikis/doc/TorifyHOWTO/Putty){:target="_blank"} by the Tor Project.

  {:.hint}
  If you are using PuTTy and fail to connect to your MobyBolt PC by setting port 9050 in the PuTTy proxy settings, try setting port 9150 instead. When Tor runs as an installed application instead of a background process it uses port 9150.

- **Linux**: use `torify` or `torsocks`.
  Both work similarly; just use whatever you have available:

  ```sh
  $ torify ssh satoshi@abcdefg..............xyz.onion
  ```

  ```sh
  $ torsocks ssh satoshi@abcdefg..............xyz.onion
  ```

- **macOS**: Using `torify` or `torsocks` may not work due to Apple's *System Integrity Protection (SIP)* which will deny access to `/usr/bin/ssh`.

  To work around this, first make sure Tor is installed and running on your Mac:

  ```sh
  $ brew install tor && brew services start tor
  ```

  You can SSH to your MobyBolt PC "out of the box" with the following proxy command:

  ```sh
  $ ssh -o "ProxyCommand nc -X 5 -x 127.0.0.1:9050 %h %p" satoshi@abcdefg..............xyz.onion
  ```

  For a more permanent solution, add these six lines below to your local SSH config file. Choose any HOSTNICKNAME you want, save and exit.

  ```sh
  $ sudo nano .ssh/config
  ```

  ```sh
  Host HOSTNICKNAME
    Hostname abcdefg..............xyz.onion
    User satoshi
    Port 22
    CheckHostIP no
    ProxyCommand /usr/bin/nc -x localhost:9050 %h %p
  ```

  Restart Tor

  ```sh
  $ brew services restart tor
  ```

  You should now be able to SSH to your MobyBolt PC with

  ```sh
  $ ssh HOSTNICKNAME
  ```

---

## Upgrade

Check the [Tor Project](https://www.torproject.org/download/tor/){:target="_blank"} for a new version and change the `TOR_VERSION` value in the `.env` file.
Then, redo the steps described in:

1. [Build](#build)
2. [Run](#run)

If everything is ok, you can clear the old image and build cache, like in the following example:

```sh
$ docker images | grep "mobybolt/tor\|TAG"
> REPOSITORY       TAG        IMAGE ID       CREATED          SIZE
> mobybolt/tor     0.4.8.13   ee5c4a10bdd0   3 minutes ago    130MB
> mobybolt/tor     0.4.8.12   3613ae3d3613   14 minutes ago   128MB
```

```sh
$ docker image rm mobybolt/tor:0.4.8.12
> Untagged: mobybolt/tor:0.4.8.12
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

Follow the next steps to uninstall tor:

1. Remove the container:

   ```sh
   $ docker compose down tor
   > [+] Running 2/1
   > ✔ Container mobybolt_tor  Removed
   > ...
   ```

2. Unlink the docker compose file

   Remove the tor line in the `include` section of the main docker compose file:

   ```sh
   $ sed -i '/- tor\/docker-compose.yml/d' docker-compose.yml
   ```

3. Remove the image:

   ```sh
   $ docker image rm $(docker images | grep mobybolt/tor | awk '{print $3}')
   > Untagged: mobybolt/tor:0.4.8.13
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
   $ docker volume rm mobybolt_tor-data
   > mobybolt_tor-data
   ```

   {:.warning}
   This will delete all tor data, including hidden services that have already been configured.

6. Remove files and directories (optional):

   ```sh
   $ rm -rf tor
   ```

---

{:.d-flex .flex-justify-between}
[<< Reverse proxy](reverse-proxy)
[I2P project >>](i2p-project)
