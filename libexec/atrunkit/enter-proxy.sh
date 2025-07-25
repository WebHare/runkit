#!/bin/bash
PID="$(podman inspect -f '{{.State.Pid}}' "runkit-proxy")"
if [ -z "$PID" ]; then
  echo Proxy container not running
  exit 255
fi

if [ "$1" != "" ]; then
  exec nsenter --all -t "$PID" "$@"
else
  PS1="[$(hostname --short)%proxy \W]\$ " nsenter --all -t "$PID" /bin/bash --noprofile --norc
fi
