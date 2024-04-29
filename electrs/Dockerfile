# base image
FROM debian:stable-slim as base

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
        cargo \
        clang \
        cmake \
        curl \
        git \
        gpg && \
    rm -rf /var/lib/apt/lists/*


# builder image
FROM base as builder

ARG ELECTRS_VERSION

ENV ELECTRS_URL="https://github.com/romanz/electrs.git" \
    ELECTRS_SIG_URL="https://romanzey.de/pgp.txt"

# clone repository
RUN set -eux && \
    git clone --branch "v$ELECTRS_VERSION" $ELECTRS_URL

WORKDIR electrs

# build electrs
RUN set -eux && \
    # import signatures
    curl $ELECTRS_SIG_URL | gpg --import && \
    # verify signatures
    git verify-tag "v$ELECTRS_VERSION" && \
    # build
    cargo build --locked --release && \
    # install
    install -m 0755 -o root -g root -t /usr/local/bin ./target/release/electrs


# result image
FROM debian:stable-slim

COPY --from=builder /usr/local/ /usr/local/

# default guid for electrs user
ARG ELECTRS_GID=1101
ARG ELECTRS_UID=1101

ARG BITCOIN_GID=1100

RUN set -xe && \
    # create electrs user
    addgroup --gid $ELECTRS_GID electrs && \
    adduser --disabled-password --comment "" --gid $ELECTRS_GID --uid $ELECTRS_UID electrs && \
    # create bitcoin group and add electrs user to bitcoin group
    addgroup --gid $BITCOIN_GID bitcoin && \
    adduser electrs bitcoin && \
    # setup dirs and permissions
    mkdir -p /home/electrs/db/ && \
    chmod 0700 /home/electrs/db/ && \
    chown -R electrs:electrs /home/electrs/db/

# setup entrypoint
COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# switch user
USER electrs
