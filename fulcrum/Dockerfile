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
    git clone --branch "v$FULCRUM_VERSION" $FULCRUM_URL

WORKDIR /Fulcrum

# install fulcrum
RUN set -eux && \
    # verify signatures
    git checkout "v$FULCRUM_VERSION" && \
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
        libqt5network5 \
        libzmq3-dev \
        python3 && \
    rm -rf /var/lib/apt/lists/*

# default uid for fulcrum user
ARG FULCRUM_GID=1101
ARG FULCRUM_UID=1101

ARG BITCOIN_GID=1100

RUN set -xe && \
    # create fulcrum user
    addgroup --gid $FULCRUM_GID fulcrum && \
    adduser --disabled-password --comment "" --gid $FULCRUM_GID --uid $FULCRUM_UID fulcrum && \
    # create bitcoin group and add fulcrum user to bitcoin group
    addgroup --gid $BITCOIN_GID bitcoin && \
    adduser fulcrum bitcoin && \
    # setup dirs and permissions
    mkdir -p /home/fulcrum/db/ /run/fulcrum/ && \
    chmod 0700 /home/fulcrum/db/ /run/fulcrum/ && \
    chown fulcrum:fulcrum /home/fulcrum/db/ /run/fulcrum/

# setup entrypoint
COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# switch user
USER fulcrum
COPY ./fulcrum-banner.txt /home/fulcrum/.fulcrum/
