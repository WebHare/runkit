#!/bin/bash

mkdir -p "$WHRUNKIT_DATADIR/_log"

# cleanup loadreports more than 4 weeks old
find "$WHRUNKIT_DATADIR/_log/loadreports" -mindepth 1 -type d -mmin +40320 -exec rm -rf {} \;

# log last daily-maintenance run
date > "$WHRUNKIT_DATADIR/_log/.last-daily-maintenance"
