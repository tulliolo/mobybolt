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

Log in to your node as `admin` user via Secure Shell (SSH).

Create the base directory structure and access it:

   ```sh
   $ mkdir -m 700 -p apps/mobybolt
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

- The `docker compose` command will automatically load all the environment variables contained in the `.env` file.

- The `docker compose` command will operate on the `docker-compose.yml` file located in the same directory where it is run. The `include` directive in the file `docker-compose.yml` will allow us to include the [YAML](https://yaml.org/){:target="_blank"} files of the Docker services that we will deploy later.

---

## Networking details

The `docker compose` command will create two project networks with the following values:

**Name** | **Type** | **Addressing** | **Subnet** | **Gateway** |
:---:|:---:|:---:|:---:|:---:
**backend** | internal | static | 172.16.21.0-127 | |
**frontend** | external | dynamic | 172.16.21.128-255 | 172.16.21.129 |

- Docker relies on networks for internal container communication.

- Containers that reside on the same network will be able to reach each other using either the IP address or the name of the service (e.g. `172.16.21.2` or `nginx`).

- Containers attached to an `internal` network won't directly have external visibility, they can reach (or be reached from) the outside through another container, e.g. tor, attached to an `external` network.

- Containers that need to reach the outside shall be in an `external` network and, if they need to be reached from the outside, they must publish a port via the `docker-compose.yml` file (Docker will automatically handle NAT, firewall, and port forwarding).

- Containers will automatically receive a **dynamic IP address** for each network the are attached to, or they can specify a **static IP address** in the `docker-compose.yml` file.

### Addressing policies

A **dynamic addressing** will be used for the **frontend external network**.

A **static addressing** (generally not necessary, since services can be invoked by name) will be used for the **backend internal network**. In fact:
- if you wanted to implement the (optional) configuration in Bitcoin Knots/Core to reject non-private networks, name resolution would be disabled and you could only reach the other containers via the IP address (which will therefore have to be static);
- with a dynamic addressing, we could have problems with nginx and tor, which will be the only access points from the outside to all the services. If we wanted to temporarily disable a non-mandatory service (e.g. BTC RPC Explorer) nginx and tor would no longer be able to resolve its name and would fail.

### Connecting services to networks

Below, a brief outline of how the services we will implement will be connected to the networks:

| | **frontend** | **backend** |
:---:|:---:|:---:
| **nginx** | &#10004; | &#10004; |
| **tor** | &#10004; | &#10004; |
| **i2p** | &#10004; | &#10004; |
| **bitcoin** | x | &#10004; |
| **lightning** | x | &#10004; |

With this configuration we will ensure that:
- only nginx, tor and i2p will reach (and be reached from) the outside;
- all the other services:
  - will reach the outside only through tor or i2p
  - will be reached from the outside only through nginx, tor or i2p

<br/>

{: .text-center}
**This is great for privacy!**
{: .fs-6}

---

{: .d-flex .flex-justify-between}
[<< Docker](../../system/docker)
[Reverse proxy (nginx) >>](reverse-proxy)
