#!/bin/bash

# short: Open a shell inside the container's network

[ -f "$WHRUNKIT_TARGETDIR/container.image" ] || die "Not running in a container"
CONTAINERNAME="runkit-wh-$WHRUNKIT_TARGETSERVER"
iscontainerup "$CONTAINERNAME" || die "Container $CONTAINERNAME is not running"
nsenter -n -u -i -t "$(podman inspect -f '{{.State.Pid}}' "$CONTAINERNAME")"
