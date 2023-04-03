#!/bin/bash

# short: Open a shell inside the container's network

[ -n "$WHRUNKIT_CONTAINERNAME" ] || die "Not running in a container"
iscontainerup "$WHRUNKIT_CONTAINERNAME" || die "Container $WHRUNKIT_CONTAINERNAME is not running"
nsenter -n -u -i -t "$(podman inspect -f '{{.State.Pid}}' "$WHRUNKIT_CONTAINERNAME")"
