#!/bin/bash
set -eo pipefail

function die_func() {
  echo "INFO: got SIGTERM... exiting"
  exit 1
}
trap die_func TERM

CMD=$@

CONF_FILE=/home/electrs/electrs.conf

if [[ $# -eq 0 ]]; then
  # missing parameters, run fulcrum
  CMD="/usr/local/bin/electrs --conf $CONF_FILE --skip-default-conf-files"
fi

exec $CMD
