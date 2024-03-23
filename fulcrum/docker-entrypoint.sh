#!/bin/bash
set -eo pipefail

function die_func() {
  echo "INFO: got SIGTERM... exiting"
  exit 1
}
trap die_func TERM

CMD=$@

CONF_DIR=/home/fulcrum/.fulcrum
CONF_FILE="$CONF_DIR/fulcrum.conf"

if [[ $# -eq 0 ]]; then
  # missing parameters, run fulcrum
  CMD="/usr/local/bin/Fulcrum $CONF_FILE"
fi

exec $CMD
