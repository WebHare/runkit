#!/bin/bash

PRIMARY=""
BASEPORT=""
RECREATE=""

function prepare_newserver()
{
  if [ -n "$PRIMARY" ]; then
    if [ -n "$BASEPORT" ]; then
      die You cannot set both --default and --baseport
    fi
  fi

  validate_servername "$WHRUNKIT_TARGETSERVER"

  settargetdir

  if [ -z "$RECREATE" ] && [ -f "$WHRUNKIT_TARGETDIR/baseport" ]; then
    echo "Server '$WHRUNKIT_TARGETSERVER' already exists"
    exit 1
  fi

  set_from_file BASEPORT "$WHRUNKIT_TARGETDIR/baseport"

  if [ -z "$BASEPORT" ]; then
    if [ -n "$PRIMARY" ]; then
      BASEPORT=13679
     else
      BASEPORT="$(( RANDOM / 10 * 10 + 20000 ))"
      # FIXME Check if in use
    fi
  fi
}
