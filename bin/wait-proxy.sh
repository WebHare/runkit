#!/bin/bash
set -e #fail on any uncaught error

# This script waits for the proxy to become available. You may want this to know when its safe to start configuring it

exit_syntax()
{
  echo "Syntax: wait-proxy.sh"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"

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

# Wait for port 5443 to open
echo -n "Waiting for NGINX"
while true; do
  if ( exec 6<>/dev/tcp/127.0.0.1/5443 ) 2>/dev/null ; then
    break;
  fi
  sleep 2
  echo -n "."
done
echo ""
