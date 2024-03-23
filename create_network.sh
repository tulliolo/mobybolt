#!/bin/bash
set -euo pipefail

source .env
docker network create --subnet $NETWORK_SUBNET --gateway $NETWORK_GATEWAY --ip-range $NETWORK_IPRANGE "$COMPOSE_PROJECT_NAME"_default