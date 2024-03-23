#!/bin/bash
set -eu

CONF_FILE=/etc/tor/torrc
DATA_DIR=/var/lib/tor/
PID_FILE=/run/tor/tor.pid

init_config () { 
  cat > $CONF_FILE <<EOF
SocksPort 0.0.0.0:9050
DataDirectory $DATA_DIR
PidFile $PID_FILE
EOF
}

if ! [[ -f $CONF_FILE ]]; then
  init_config
fi

CMD=$@
if [[ $# -eq 0 ]]; then
  # missing parameters, run tor
  CMD=tor
  CMD="$CMD -f $CONF_FILE"
  $CMD --verify-config
fi

exec $CMD
