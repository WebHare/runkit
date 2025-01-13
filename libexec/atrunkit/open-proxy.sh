#!/bin/bash

if ! "$WHRUNKIT_CONTAINERENGINE" inspect runkit-proxy >/dev/null 2>&1; then
  # Test if a softlink exists
  if [ -L "$WHRUNKIT_DATADIR/_settings/projectlinks/proxy" ]; then
    PROXYPROJECT="$(readlink "$WHRUNKIT_DATADIR/_settings/projectlinks/proxy")"
    ADMINKEY="$(cat "$PROXYPROJECT/localdata/etc/secret.key")"
    if [ -z "$ADMINKEY" ]; then
      echo "Cannot find the admin key in the proxy project"
      exit 1
    fi
    echo $ADMINKEY
    open "http://webhare:${ADMINKEY}@127.0.0.1:5080/"
    exit 0
  fi

  echo "The proxy (runkit-proxy container) is not running!"
  exit 1
fi
