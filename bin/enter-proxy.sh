#!/bin/bash
source "${BASH_SOURCE%/*}/../libexec/runkit-functions.sh"
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: enter-proxy.sh"
  exit 1
}

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

[ -n "$1" ] && exit_syntax

if ! iscontainerup runkit-proxy ; then
  echo The proxy container is not running
  exit 1
fi

exec docker exec -ti runkit-proxy /bin/bash "$@"
