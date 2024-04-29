#!/bin/bash
set -eo pipefail

function die_func() {
  echo "INFO: got SIGTERM... exiting"
  exit 1
}
trap die_func TERM

function wait_for_config () {
  echo "WARNING: missing configuration file"
  while ! [[ -f $CONF_FILE ]]; do
    echo "--> waiting for $CONF_FILE"
    sleep 30
  done
  echo "INFO: found configuration file!"
}

CMD=$@

DATA_DIR=/home/bitcoin/.bitcoin
CONF_FILE="$DATA_DIR/bitcoin.conf"
PID_FILE=/run/bitcoind/bitcoind.pid

if [[ $# -eq 0 ]]; then
  # missing parameters, run bitcoind
  CMD="bitcoind -conf=$CONF_FILE -datadir=$DATA_DIR -pid=$PID_FILE"
  if ! [[ -f $CONF_FILE ]]; then
    wait_for_config
  fi
fi

exec $CMD
