#!/bin/bash
source "${BASH_SOURCE%/*}/../libexec/functions.sh"
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: enter-proxy.sh"
  exit 1
}

for P in $(docker ps -q --filter=label=runkittype) ; do
  docker stop $P
done
