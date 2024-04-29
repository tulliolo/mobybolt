# base image
FROM node:lts as base

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y \
      curl \
      git && \
    rm -rf /var/lib/apt/lists/*


# builder image
FROM base as builder

ARG BTCEXP_VERSION

ENV BTCEXP_GIT_URL="https://github.com/janoside/btc-rpc-explorer.git" \
    BTCEXP_SIG_URL="https://github.com/janoside.gpg"

# import signatures and clone repository
RUN set -eux && \
    curl "$BTCEXP_SIG_URL" | gpg --import && \
    git clone --branch "v$BTCEXP_VERSION" "$BTCEXP_GIT_URL"

WORKDIR /btc-rpc-explorer

RUN set -eux && \
    # check signatures
    git verify-commit "v$BTCEXP_VERSION" && \
    # install btcrpcexplorer
    npm install

    
# result image
FROM node:lts

# install dependencies
RUN set -eux && \
    apt update && \
    apt install -y curl && \
    rm -rf /var/lib/apt/lists/*

# default uid for btcrpcexplorer user
ARG BTCEXP_GID=1102
ARG BTCEXP_UID=1102

ARG BITCOIN_GID=1100

RUN set -xe && \
    # set node user and group guid
    groupmod -g $BTCEXP_GID node && \
    usermod -u $BTCEXP_UID node && \
    # create bitcoin group and add node user to bitcoin group
    addgroup --gid $BITCOIN_GID bitcoin && \
    adduser node bitcoin

# copy app
COPY --from=builder --chown=node:node /btc-rpc-explorer/ /home/node/

# switch user
USER node
WORKDIR /home/node
ENTRYPOINT ["npm", "start"]
