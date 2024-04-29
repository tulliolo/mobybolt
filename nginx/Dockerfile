ARG NGINX_VERSION='latest'

# cert image
FROM alpine as certimage

ARG DOMAIN_NAME=localhost
ARG DAYS_VALID=3650

# install dependencies
RUN set -eux && \
    apk add --no-cache openssl

RUN set -eux && \
    echo "Creating self-signed certificate valid for ${DAYS_VALID} days for domain ${DOMAIN_NAME}" && \
    openssl \
      req -x509 \
      -nodes \
      -subj "/CN=${DOMAIN_NAME}}" \
      -addext "subjectAltName=DNS:${DOMAIN_NAME}" \
      -days ${DAYS_VALID} \
      -newkey rsa:4096 \
      -keyout /tmp/nginx-selfsigned.key \
      -out /tmp/nginx-selfsigned.crt


# base image
FROM nginx:$NGINX_VERSION as base

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y curl && \
    rm -rf /var/lib/apt/lists/*


# result image
FROM base

ARG NGINX_GID=101
ARG NGINX_UID=101

# copy certificates
COPY --from=certimage /tmp/nginx-selfsigned.crt /tmp/nginx-selfsigned.key /etc/nginx/ssl/

RUN set -eux && \
    # setup user
    groupmod --gid $NGINX_GID nginx && \
    usermod --uid $NGINX_UID nginx && \
    # setup dirs
    mkdir /run/nginx/ && \
    # set ownership and permissions
    chown -R nginx:nginx /etc/nginx/ /run/nginx/ /var/cache/nginx/

# switch user
USER nginx
