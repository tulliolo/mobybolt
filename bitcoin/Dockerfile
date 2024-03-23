# builder image
FROM debian:stable-slim as builder

ARG BITCOIN_VERSION

ENV BITCOIN_KEYS="E777299FC265DD04793070EB944D35F9AC3DB76A D1DBF2C4B96F2DEBF4C16654410108112E7EA81F 152812300785C96444D3334D17565732E08E5E41 6B002C6EA3F91B1B0DF0C9BC8F617F1200A6D25C 4D1B3D5ECBA1A7E05371EEBE46800E30FC748A66" \
    BITCOIN_URL="https://github.com/bitcoin/bitcoin.git"

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
      automake \
      autotools-dev \
      bsdmainutils \
      build-essential \
      curl \
      git \
      libboost-dev \
      libevent-dev \
      libsqlite3-dev \
      libtool \
      libzmq3-dev \
      pkg-config \
      python3 && \
    rm -rf /var/lib/apt/lists/*

# copy patches
COPY patches/* /patches/

RUN set -eux && \
    # import keys
    gpg --keyserver hkps://keys.openpgp.org --recv-keys $BITCOIN_KEYS && \
    # clone repository
    git clone $BITCOIN_URL

WORKDIR bitcoin

RUN set -xe && \
    # verify signature
    git verify-tag "v$BITCOIN_VERSION" && \
    # checkout version
    git checkout "v$BITCOIN_VERSION" && \
    # build bdb 4.8
    make -C depends NO_BOOST=1 NO_LIBEVENT=1 NO_QT=1 NO_SQLITE=1 NO_NATPMP=1 NO_UPNP=1 NO_ZMQ=1 NO_USDT=1 && \
    # apply patches
    for patch in $( find /patches -type f ); do \
        git apply $patch; \
    done && \
    # build bitcoin
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
    make -j$(nproc) && \
    make install


# base image
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

# setup bitcoin user
RUN set -eux && \
    addgroup --gid $BITCOIN_GID bitcoin && \
    adduser --disabled-password --comment "" --gid $BITCOIN_GID --uid $BITCOIN_UID bitcoin && \
    addgroup --gid $TOR_GID tor && \
    adduser bitcoin tor

# setup dirs and permissions
RUN set -eux && \
    mkdir -m 0700 /run/bitcoind && \
    chown bitcoin /run/bitcoind

# setup entrypoint
COPY --chmod=0755 ./docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# switch user
USER bitcoin
