---
layout: default
title: I2P project
nav_order: 40
parent: + Setup
grand_parent: MobyBolt
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# I2P project
{:.no_toc}

{:.text-center}
![i2p logo](../../../images/mobybolt-setup-i2p-project_logo.png){:width="25%"}

[I2P](https://geti2p.net/en/){:target="_blank"} is a universal anonymous network layer. All communications over I2P are anonymous and end-to-end encrypted, participants don't reveal their real IP addresses. I2P allows people from all around the world to communicate and share information without restrictions.

I2P client is software used for building and using anonymous I2P networks. Such networks are commonly used for anonymous peer-to-peer applications (filesharing, cryptocurrencies) and anonymous client-server applications (websites, instant messengers, chat-servers).

We are to use [i2pd](https://i2pd.readthedocs.io/en/latest/){:target="_blank"} (I2P Daemon), a full-featured C++ implementation of the I2P client, as a Tor network complement. We'll use the [official docker image](https://hub.docker.com/r/purplei2p/i2pd){:target="_blank"} for the installation.

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

Create the i2p directory:

```sh
$ mkdir i2p
```

### Prepare the environment

Edit the `.env` file and append the following content to the end:

```sh
$ nano .env
```

```ini
# i2p
I2P_VERSION=latest-release
I2P_ADDRESS=172.16.21.4
```

In this file:
1. we define the `I2P_VERSION` as the latest (stable) available;
2. we define a static address for the container.

### Prepare the docker compose file

Create a i2p-specific docker compose file and populate it with the following contents:

```sh
$ nano i2p/docker-compose.yml
```

```yaml
services:
  i2p:
    container_name: ${COMPOSE_PROJECT_NAME}_i2p
    expose:
      - "2827" 
      - "4444"
      - "4447"
      - "7070"
      - "7650"
      - "7654"
      - "7656"
    image: purplei2p/i2pd:${I2P_VERSION}
    networks:
      frontend:
      backend:
        ipv4_address: ${I2P_ADDRESS}
    restart: unless-stopped
    stop_grace_period: 30s
    volumes:
      - i2p-data:/home/i2pd/data/
  
volumes:
  i2p-data:
```

In this file:
1. we pull the i2pd `image`;
2. we define the `restart` policy of the container in case of failures;
3. we provide the container with the `I2P_ADDRESS` static address;
4. we provide the container with a [volume](https://docs.docker.com/storage/volumes/) named `mobybolt_i2p-data` to store persistent data.

### Link the docker compose file

Link the i2p-specific docker compose file in the main one by running:

```sh
$ sed -i '/^networks:/i \ \ - i2p/docker-compose.yml' docker-compose.yml
```

The file should look like this:

```sh
$ cat docker-compose.yml
```

```yaml
include:
  - ...
  - i2p/docker-compose.yml
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

## Run

Run the following command and check the output:

```sh
$ docker compose up -d i2p
> ...
> [+] Running 2/2
> ✔ Volume "mobybolt_i2p-data"  Created
> ✔ Container mobybolt_i2p      Started
```

Check the container status:

```sh
$ docker compose ps | grep "i2p\|NAME"
> NAME                      IMAGE                                  COMMAND                  SERVICE          CREATED        STATUS                 PORTS
> mobybolt_i2p              purplei2p/i2pd:latest-release          "/entrypoint.sh"         i2p              30 hours ago   Up 2 hours             2827/tcp, 4444/tcp, 4447/tcp, 7070/tcp, 7650/tcp, 7654/tcp, 7656/tcp
```

{:.note}
>If not already present, docker will also create the `mobybolt_i2p-data` volume. You can check for it with the command:
>
>```sh
>$ docker volume ls | grep "i2p\|DRIVER"
>> DRIVER    VOLUME NAME
>> local     mobybolt_i2p-data
>```

---

## Upgrade

To update i2p, try downloading a new version from GitHub with the command:

```sh
$ docker compose pull i2p
```

You can apply the new image by following the steps in the [Run](#run) section again.

If everything is ok, you can clear the old image by running the following command and typing `y` when prompted:

```sh
$ docker image prune
> WARNING! This will remove all dangling images.
> Are you sure you want to continue? [y/N] y
> ...
```

---

## Uninstall

Follow the next steps to uninstall i2p:

1. Remove the container:

   ```sh
   $ docker compose down i2p
   > [+] Running 2/1
   > ✔ Container mobybolt_i2p  Removed
   > ...
   ```

2. Unlink the docker compose file

   Remove the i2p line in the `include` section of the main docker compose file:

   ```sh
   $ sed -i '/- i2p\/docker-compose.yml/d' docker-compose.yml
   ```

3. Remove the image:

   ```sh
   $ docker image rm $(docker images | grep i2p | awk '{print $3}')
   > Untagged: purplei2p/i2pd:latest-release
   > ...
   ```

4. Remove the volume (optional):

   ```sh
   $ docker volume rm mobybolt_i2p-data
   > mobybolt_i2p-data
   ```

5. Remove files and directories (optional):

   ```
   $ rm -rf i2p
   ```

---

{:.d-flex .flex-justify-between}
[<< Tor project](tor-project)
[Bitcoin client >>](../bitcoin/bitcoin-client)