#!/bin/bash

# TODO can we set an explcit nam
ADMINKEY="$(runkit get-proxy-key || true)"
WEBHAREPROXY_ADMINHOSTNAME="localhost:5080"
WEBHAREPROXY_ADMINPATH="/"

if [ -z "$ADMINKEY" ]; then
  echo "Proxy admin key not set" 1>&2
  exit 1
fi

if [ -f "$WHRUNKIT_DATADIR/_settings/publichostname" ]; then
  WEBHAREPROXY_ADMINHOSTNAME="$(cat "$WHRUNKIT_DATADIR/_settings/publichostname")"
  WEBHAREPROXY_ADMINPATH="/admin"
fi

open "http://webhare:${ADMINKEY}@${WEBHAREPROXY_ADMINHOSTNAME}${WEBHAREPROXY_ADMINPATH}"
exit 0
