#!/bin/bash

PRIMARY=""
BASEPORT=""

function prepare_newserver()
{
  if [ -n "$PRIMARY" ]; then
    if [ -n "$BASEPORT" ]; then
      die You cannot set both --default and --baseport
    fi
    BASEPORT=13679
  fi

  if [ -z "$BASEPORT" ]; then
    BASEPORT="$(( RANDOM / 10 * 10 + 20000 ))"
    # FIXME Check if in use
  fi

  validate_servername "$WHRUNKIT_TARGETSERVER"

  settargetdir

  if [ -f "$WHRUNKIT_TARGETDIR/baseport" ]; then
    echo "Server '$WHRUNKIT_TARGETSERVER' already exists"
    exit 1
  fi
}

