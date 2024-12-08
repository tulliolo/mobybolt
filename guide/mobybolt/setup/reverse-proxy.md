---
layout: default
title: Reverse proxy (nginx)
nav_order: 20
parent: + Setup
grand_parent: MobyBolt
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Reverse proxy (nginx)
{: .no_toc}

{: .text-center}
![nginx logo](../../../images/mobybolt-setup-reverse-proxy_logo.png){: width="20%"}

Several components of this guide will expose a communication port, for example, the Block Explorer, or the ThunderHub web interface for your Lightning node. Even if you use these services only within your own home network, communication should always be encrypted. Otherwise, any device in the same network can listen to the exchanged data, including passwords.

We use nginx (it is pronounced *Engine X*) to encrypt the communication with SSL/TLS (Transport Layer Security). This setup is called a "reverse proxy": nginx provides secure communication to the outside and routes the traffic back to the internal service without encryption.

{: .note}
Even if some services, such as Fulcrum, natively support encrypted communication, for simplicity and architectural cleanliness, we will still use nginx as a single point of access to all services.

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

Let's create the directory structure for nginx:

```sh
$ mkdir -p nginx/streams-enabled
```

### Generate a self-signed SSL/TLS certificate (valid for 10 years)

```sh
$ sudo openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/CN=localhost" -days 3650
```

### Prepare the environment

Edit the `.env` file and append the following content to the end:

```sh
$ nano .env
```

```conf
# nginx
NGINX_ADDRESS=172.16.21.2
```

In this file, we have defined the static IP address that nginx will use on the backend network.

### Configure nginx

Create the `nging.conf` file and paste the following contents:

```sh
$ nano nginx/nginx.conf
```

```nginx
user nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;
worker_rlimit_nofile  1536;

events {
  worker_connections  768;
}

http {
  ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
  ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
  ssl_session_cache shared:HTTP-TLS:1m;
  ssl_session_timeout 4h;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers on;
  include /etc/nginx/sites-enabled/*.conf;

  server {
    listen 80;
    location / {
      root   /usr/share/nginx/html;
      index  index.html index.htm;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
  }
  
  server {
    listen 443 ssl;
    error_page 497 =301 https://$host:$server_port$request_uri;
    location / {
      proxy_pass http://127.0.0.1:80;
    }
  }
}

stream {
  ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
  ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
  ssl_session_cache shared:SSL:1m;
  ssl_session_timeout 4h;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers on;

  include /etc/nginx/conf.d/*.conf;
}
```

### Prepare the docker-compose file

Create a nginx-specific docker-compose file and paste the following contents:

```sh
$ nano nginx/docker-compose.yml
```

```yaml
services:
  nginx:
    container_name: ${COMPOSE_PROJECT_NAME}_nginx
    healthcheck:
      test: ["CMD-SHELL", "curl -fk https://localhost || exit 1"]
      interval: 1m
      timeout: 10s
      retries: 3
    image: nginx
    networks:
      - frontend
      - backend
    restart: unless-stopped
    volumes:
      - /etc/ssl/certs/nginx-selfsigned.crt:/etc/ssl/certs/nginx-selfsigned.crt:ro
      - /etc/ssl/private/nginx-selfsigned.key:/etc/ssl/private/nginx-selfsigned.key:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./streams-enabled/:/etc/nginx/conf.d/:ro
```

{: .warning}
Be very careful to respect the indentation above, since yaml is very sensitive to this!

In this file:

- we define a `healthcheck` for the container: every minute, docker will query the nginx service to check its status; after three failed attempts, the container will be marked `unhealthy`;

- we define the `image` to be used: the `nginx` (official) image will be downloaded from the [DockerHub](https://hub.docker.com/_/nginx){: target="_blank"} public repository;

- we attach the nginx container to the `backend` and `frontend` `networks`: nginx will receive connection requests on the frontend network and redirect them to the affected services via the backend network;

- we define the `restart` policy `unless-stopped` for the container: this way, the container will always be automatically restarted, unless it has been stopped explicitly.

- we define some read-only [bind-mount](https://docs.docker.com/engine/storage/bind-mounts/){: target="_blank"} `volumes` to provide the container with certificates and configuration files;

### Link the docker-compose file

Edit the main docker-compose file and link the nginx-specific one to the `include` section:

```sh
$ nano docker-compose.yml
```

The file should look like this:

```yaml
include:
  - nginx/docker-compose.yml
```

{: .warning}
Be very careful to respect the indentation above, since yaml is very sensitive to this!

---

## Test

### Test the docker-compose file

Run the following command and check the output:

```sh
$ docker compose config --quiet && printf "OK\n" || printf "ERROR\n"
> OK
```

{: .hint}
If the output is `ERROR`, check the error reported... Maybe some wrong indentation in the yaml files?

### Test the nginx configuration

Run the following command and check the output:

```sh
$ docker compose run --rm nginx nginx -t
> ...
> nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
> nginx: configuration file /etc/nginx/nginx.conf test is successful
```

{: .hint}
If the output reports an error, please review the [nginx configuration file](#configure-nginx).

{: .note}
>If the nginx image is not already present, docker will automatically pull it from DockerHub.
>Check for the presence of the image with the command:
>
>```sh
>$ docker images | grep "nginx\|TAG"
>> REPOSITORY                          TAG                  IMAGE ID       CREATED           SIZE
>> nginx                               latest               64ea9ecb52dd   37 seconds ago    192MB
>```

---

## Run

Run the following command and check the output:

```sh
$ docker compose up -d nginx
> [+] Running 3/3
> ✔ Network mobybolt_backend   Created 
> ✔ Network mobybolt_frontend  Created 
> ✔ Container mobybolt_nginx   Started
```

Check the container logs:

```sh
$ docker compose logs nginx
> ...
> 2024/05/07 11:50:50 [notice] 1#1: nginx/1.25.5
> 2024/05/07 11:50:50 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
> 2024/05/07 11:50:50 [notice] 1#1: OS: Linux 6.1.0-20-amd64
> 2024/05/07 11:50:50 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
> 2024/05/07 11:50:50 [notice] 1#1: start worker processes
> ...
```

Check the container status:

```sh
$ docker compose ps | grep "nginx\|NAME"
> NAME              IMAGE     COMMAND                  SERVICE     CREATED         STATUS                   PORTS
> mobybolt_nginx    nginx     "/docker-entrypoint.…"   nginx       5 minutes ago   Up 5 minutes (healthy)   80/tcp
```

{: .warning}
>The `STATUS` of the previous command must be `(healthy)`, or `(health: starting)`. Any other status is incorrect.
>
>If the container is in `(health: starting)` status, wait a few minutes and repeat the above command until the status changes to `(healthy)`. If this does not happen, the run has failed.

{: .note}
>If not already present, docker will also create the mobybolt networks. You can check for it with the command:
>
>```sh
>$ docker network ls | grep "mobybolt\|NAME"
> NETWORK ID     NAME                DRIVER    SCOPE
> b73804f9dc97   mobybolt_backend    bridge    local
> d1572b999173   mobybolt_frontend   bridge    local
```

---

## Upgrade

To update nginx, try downloading a new version from DockerHub with the command:

```
$ docker compose pull nginx
```

You can apply the new image by following the steps in the [Run](#run) section again.

If everything is ok, you can clear the old image by running the following command and typing `y` when prompted:

```
$ docker image prune
> WARNING! This will remove all dangling images.
> Are you sure you want to continue? [y/N] y
> ...
```

## Uninstall

Follow the next steps to uninstall nginx:

1. Remove the container:
   ```
   $ docker compose down nginx
   > [+] Running 3/1
   > ✔ Container mobybolt_nginx  Removed
   > ...
   ```

2. Remove the image:
   ```
   > $ docker image rm nginx
   > Untagged: nginx:latest
   > ...
   ```

4. Remove files and directories (optional):
   ```
   $ rm -rf nginx
   ```

---

{: .d-flex .flex-justify-between}
[<< Project backup](project-backup)
[Tor project >>](tor-project)