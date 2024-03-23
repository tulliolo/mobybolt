# builder image
FROM debian:stable-slim as builder

ARG TOR_VERSION

ENV TOR_KEYS="514102454D0A87DB0767A1EBBE6A0531C18A9179 B74417EDDF22AC9F9E90F49142E86A2A11F48D36 7A02B3521DC75C542BA015456AFEE6D49E92B601"
ENV TOR_URL="https://dist.torproject.org"

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


#base image
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
ARG TOR_GID=102
ARG TOR_UID=102

RUN set -eux && \
    addgroup --gid $TOR_GID tor && \
    adduser --system --gecos "" --gid $TOR_GID --home /var/lib/tor/ --uid $TOR_UID tor && \
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
