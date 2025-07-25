#!/bin/bash

mkdir -p "$WHRUNKIT_DATADIR/_log"

# cleanup loadreports more than 4 weeks old
find "$WHRUNKIT_DATADIR/_log/loadreports" -mindepth 1 -type d -mmin +40320 -exec rm -rf {} \;

# log last daily-maintenance run
date > "$WHRUNKIT_DATADIR/_log/.last-daily-maintenance"

# Prune old containers
if hash podman >/dev/null 2>/dev/null ; then
  podman container prune --force --filter until="48h"

  # limiting delete images older than 7 days to prevent too early removal of build artifacts.
  podman image prune -a --force --filter until="168h"
  podman builder prune --force --filter until="168h"
  podman volume prune --force
fi
