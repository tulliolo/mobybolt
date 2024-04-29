# base image
FROM debian:stable-slim as base

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
        # build requirements
        automake \
        autotools-dev \
        bsdmainutils \
        build-essential \
        ccache \
        curl \
        git \
        imagemagick \
        librsvg2-bin \
        libtool \
        pkg-config \
        python3 \
        # dependencies
        libboost-dev \
        libevent-dev \
        libsqlite3-dev \
        libzmq3-dev && \    
    rm -rf /var/lib/apt/lists/*


# builder image
FROM base as builder

ARG BITCOIN_VERSION

ENV BITCOIN_URL="https://github.com/bitcoinknots/bitcoin.git" \
    BITCOIN_KEYS_URL="https://api.github.com/repositories/355107265/contents/builder-keys"

RUN set -eux && \
    # clone repository
    git clone --branch "v$BITCOIN_VERSION" $BITCOIN_URL  && \
    # imports automatically all signatures from the Bitcoin Core release attestations (Guix) repository
    curl -s \
        $BITCOIN_KEYS_URL |\
        grep download_url |\
        grep -oE "https://[a-zA-Z0-9./-]+" |\
        while read url; do \
            curl -s "$url" |\
            gpg --import; \
        done

# copy patches
COPY patches/ /patches/

WORKDIR bitcoin

RUN set -xe && \
    # verify signature
    git verify-tag "v$BITCOIN_VERSION" && \
    # build bdb 4.8 (for legacy wallet)
    make -C depends NO_BOOST=1 NO_LIBEVENT=1 NO_QT=1 NO_SQLITE=1 NO_NATPMP=1 NO_UPNP=1 NO_ZMQ=1 NO_USDT=1 && \
    # apply patches (if any)
    for patch in $( find /patches -type f ); do \
        git apply $patch; \
    done && \
    # configure
    ./autogen.sh && \
    export BDB_PREFIX="$PWD/depends/$( ls depends | grep linux-gnu )" && \
    ./configure \
        BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BDB_PREFIX}/include" \
        --disable-bench \
        --disable-gui-tests \
        --disable-maintainer-mode \
        --disable-man \
        --disable-tests \
        --with-daemon=yes \
        --with-gui=no \
        --with-qrencode=no \
        --with-utils=yes && \
    # build
    make -j$(nproc) && \
    # install
    make install


# result image
FROM debian:stable-slim

# copy bitcoin binaries and libraries
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
        libevent-dev \
        libsqlite3-dev \
        libzmq3-dev && \
    rm -rf /var/lib/apt/lists/*

# default uid for bitcoin user
ARG BITCOIN_GID=1100
ARG BITCOIN_UID=1100

# default gid for tor group
ARG TOR_GID=102

RUN set -eux && \
    # setup bitcoin user
    addgroup --gid $BITCOIN_GID bitcoin && \
    adduser --disabled-password --comment "" --gid $BITCOIN_GID --uid $BITCOIN_UID bitcoin && \
    addgroup --gid $TOR_GID tor && \
    adduser bitcoin tor && \
    # setup dirs and permissions
    mkdir -m 0750 /home/bitcoin/.bitcoin && \
    mkdir -m 0700 /run/bitcoind && \
    chown bitcoin:bitcoin /home/bitcoin/.bitcoin /run/bitcoind

# setup entrypoint
COPY --chmod=0755 ./docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# switch user
USER bitcoin
