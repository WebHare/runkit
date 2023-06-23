#!/bin/bash

if ! podman inspect runkit-proxy >/dev/null 2>&1;  then
  echo "The proxy (runkit-proxy container) is not running!"
  exit 1
fi

