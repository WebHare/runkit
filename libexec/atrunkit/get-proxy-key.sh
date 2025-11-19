#!/bin/bash

set -eo pipefail

exit_syntax()
{
  echo "Syntax: runkit get-proxy-key"
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

WEBHAREPROXY_DATAROOT="$(cat "$WHRUNKIT_DATADIR/_proxy/dataroot" 2>/dev/null || true)"
if [ -z "$WEBHAREPROXY_DATAROOT" ]; then # not explicitly set
  WEBHAREPROXY_DATAROOT="$WHRUNKIT_DATADIR/_proxy/data"
fi

if ! [ -f "$WEBHAREPROXY_DATAROOT/etc/secret.key" ]; then
  echo "No proxy secret key found in dataroot" >&2
  exit 1
fi

KEY="$(cat "$WEBHAREPROXY_DATAROOT/etc/secret.key")"
echo "$KEY"
