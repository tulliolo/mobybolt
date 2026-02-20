---
layout: default
title: Project setup
nav_order: 10
parent: + Setup
grand_parent: MobyBolt
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Project setup
{: .no_toc}

We create the base directory structure and files.

---

## Table of contents
{: .no_toc .text-delta}

1. TOC
{:toc}

---

## Create the base files and directories

Log in to your node as `satoshi` user via Secure Shell (SSH).

Create the base directory structure and access it:

   ```sh
   $ mkdir -p apps/mobybolt
   $ cd apps/mobybolt
   ```

### Create the env file

Create the base env file and populate it as follows:

```sh
$ nano .env
```

```ini
# base env
COMPOSE_PROJECT_NAME=mobybolt

NETWORK_BACKEND_SUBNET=172.16.21.0/25

NETWORK_FRONTEND_SUBNET=172.16.21.128/25
NETWORK_FRONTEND_GATEWAY=172.16.21.129
```

In this file, we define the `frontend` and `backend` network parameters, as defined [here](../../mobybolt#network-isolation).

### Create the docker compose file

Create the base [docker compose file](https://docs.docker.com/compose/compose-file/compose-file-v3/){:target="_blank"} and populate it as follows:

```sh
$ nano docker-compose.yml
```

{: .warning}
Be very careful to respect the indentation below, since yaml is very sensitive to this!

```yaml
include:
networks:
  frontend:
    ipam:
      config:
        - subnet: ${NETWORK_FRONTEND_SUBNET}
          gateway: ${NETWORK_FRONTEND_GATEWAY}
  backend:
    internal: true
    ipam:
      config:
        - subnet: ${NETWORK_BACKEND_SUBNET}
```

In this file, we prepare the creation of the `frontend` and `backend` networks, as defined [here](../../mobybolt#network-isolation).

The `docker compose` command will automatically load all the environment variables contained in the `.env` file.

The `docker compose` command will operate on the `docker-compose.yml` file located in the same directory where it is run. The `include` directive in the file `docker-compose.yml` will allow us to include the [YAML](https://yaml.org/){:target="_blank"} files of the Docker services that we will deploy later.

### Test the docker compose file

Run the following command and check the output:

```sh
$ docker compose config --quiet && printf "OK\n" || printf "ERROR\n"
> OK
```

{: .hint}
If the output is `ERROR`, check the error reported... Maybe some wrong indentation in the yaml files?

---

## Uninstall

You can follow the next steps to uninstall the whole suite:

{:.important}
If you have an active Lightning node, make sure you have a backup of all the data you need to recover the funds.

1. Log in to your node as `satoshi` user via Secure Shell (SSH) and access the project's home:

   ```sh
   $ cd apps/mobybolt
   ```

2. Remove all the running services:

   ```sh
   $ docker compose down
   > [+] Running n/m
   > ✔ Container mobybolt_nginx   Removed 
   > ✔ Container mobybolt_tor     Removed
   > ...
   > ✔ Network mobybolt_frontend  Removed 
   > ✔ Network mobybolt_backend   Removed 
   ```

3. Remove all the images:

   ```sh
   $ docker image rm $(docker images | grep 'mobybolt\|nginx\|i2pd' | awk '{print $3}')
   > ...
   > Untagged: mobybolt/tor:0.4.9.5
   > Deleted: sha256:ee5c4a10bdd0653c0482192a97d5e16c570c7389f323f3008b9c76cab7a8eaf9
   > Untagged: nginx:latest
   > Deleted: sha256:2c250073ded2286f819a9c025bfe9d87250d1f7a37ab236a7b61aec31e4c63d8
   > ...
   ```

4. Clear the build cache:

   ```sh
   $ docker buildx prune
   > WARNING! This will remove all dangling build cache. Are you sure you want to continue? [y/N] y
   > ID                                              RECLAIMABLE     SIZE            LAST ACCESSED
   > r4y2gpo6s0x0kjysuktg38z8y                       true            398B            6 hours ago
   > in97ma2g57e956xc84k8mu0hv                       true            15.38kB         44 hours ago
   > ...
   ``` 

5. Remove all the volumes (optional):

   {:.warning}
   This will remove all the persistent data (e.g. the blockchain, the lnd data ecc...). Don't do this if you plan to reinstall.

   ```sh
   $ docker volume rm $(docker volume ls | grep mobybolt | awk '{print $2}')
   > ...
   > mobybolt_tor-data
   > ...
   ```

6. Remove files and directories (optional):

   ```sh
   $ cd
   $ rm -rf apps/mobybolt
   ```

---

{: .d-flex .flex-justify-between}
[<< MobyBolt](../)
[Project backup >>](project-backup)
