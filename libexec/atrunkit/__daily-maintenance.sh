#!/bin/bash

mkdir -p "$WHRUNKIT_DATADIR/_log"

# cleanup loadreports more than 4 weeks old
find "$WHRUNKIT_DATADIR/_log/loadreports" -mindepth 1 -type d -mmin +40320 -exec rm -rf {} \;

# log last daily-maintenance run
date > "$WHRUNKIT_DATADIR/_log/.last-daily-maintenance"

# Prune old docker/podman containers
if hash docker >/dev/null 2>/dev/null ; then
  docker container prune --force --filter until="48h"

  # https://docs.docker.com/engine/reference/commandline/image_prune/#filtering
  # limiting delete images older than 7 days to prevent too early removal of build artifacts.
  docker image prune -a --force --filter until="168h"
  docker builder prune --force --filter until="168h"
  docker volume prune --force
fi

if hash podman >/dev/null 2>/dev/null ; then
  podman container prune --force --filter until="48h"

  # limiting delete images older than 7 days to prevent too early removal of build artifacts.
  podman image prune -a --force --filter until="168h"
  podman builder prune --force --filter until="168h"
  podman volume prune --force
fi
