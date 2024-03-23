# builder image
FROM debian:stable-slim as builder

ARG FULCRUM_VERSION
ENV FULCRUM_URL="https://github.com/cculianu/Fulcrum/releases/download/v$FULCRUM_VERSION" \
    FULCRUM_SIG_URL="https://raw.githubusercontent.com/Electron-Cash/keys-n-hashes/master/pubkeys/calinkey.txt"

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
      gpg \
      gpg-agent && \
    rm -rf /var/lib/apt/lists/*

ADD "$FULCRUM_URL/Fulcrum-$FULCRUM_VERSION-x86_64-linux.tar.gz" \
    "$FULCRUM_URL/Fulcrum-$FULCRUM_VERSION-shasums.txt.asc" \
    "$FULCRUM_URL/Fulcrum-$FULCRUM_VERSION-shasums.txt" \
    "$FULCRUM_SIG_URL" /tmp/

WORKDIR /tmp/

# install fulcrum
RUN set -eux && \
    gpg --import calinkey.txt && \
    gpg --verify "Fulcrum-$FULCRUM_VERSION-shasums.txt.asc" && \
    grep 'x86_64-linux.tar.gz' "Fulcrum-$FULCRUM_VERSION-shasums.txt" | sha256sum --check && \
    tar -xvf "Fulcrum-$FULCRUM_VERSION-x86_64-linux.tar.gz" && \
    install -m 0755 -o root -g root -t /usr/local/bin "Fulcrum-$FULCRUM_VERSION-x86_64-linux/Fulcrum" "Fulcrum-$FULCRUM_VERSION-x86_64-linux/FulcrumAdmin" && \
    Fulcrum --version


# base image
FROM debian:stable-slim
COPY --from=builder /usr/local/ /usr/local/

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
      libssl-dev \
      python3 && \
    rm -rf /var/lib/apt/lists/*

# default uid for fulcrum user
ARG FULCRUM_GID=1101
ARG FULCRUM_UID=1101

ARG BITCOIN_GID=1100

RUN set -xe && \
    # create fulcrum user
    addgroup --gid $FULCRUM_GID fulcrum && \
    adduser --disabled-password --gecos "" --gid $FULCRUM_GID --uid $FULCRUM_UID fulcrum && \
    # create bitcoin group and add fulcrum user to bitcoin group
    addgroup --gid $BITCOIN_GID bitcoin && \
    adduser fulcrum bitcoin

# setup entrypoint
COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# setup dirs and permissions
RUN set -xe && \
    mkdir -p /home/fulcrum/.fulcrum/fulcrum_db/ && chmod 0700 /home/fulcrum/.fulcrum/fulcrum_db/ && chown -R fulcrum:fulcrum /home/fulcrum/.fulcrum/ && \
    mkdir /run/fulcrum/ && chmod 0700 /run/fulcrum/ && chown fulcrum:fulcrum /run/fulcrum/

# switch user
USER fulcrum
COPY ./fulcrum-banner.txt /home/fulcrum/.fulcrum/
