#!/bin/bash

WEBHARE_RUNKIT_ROOT="$(cd ${BASH_SOURCE%/*}/.. ; pwd )"
WEBHARE_RUNKIT_KEYFILE=""

onexit()
{
  rv=$? #Make sure we don't destroy the exit code
  [ -n "$WEBHARE_RUNKIT_KEYFILE" ] && rm "$WEBHARE_RUNKIT_KEYFILE"
  exit $rv
}

trap onexit EXIT

function ensurecommands()
{
  if ! hash "$@" >/dev/null 2>&1 ; then
    "$WEBHARE_RUNKIT_ROOT/bin/setup.sh"
  fi
}

function iscontainerup()
{
  [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null )" == true ] && return 0 || return 1
}

function killcontainer()
{
  if docker inspect "$1" > /dev/null 2>&1 ; then
    (docker stop "$1" 2>/dev/null && sleep 1) || true
    docker kill "$1" 2>/dev/null || true
    docker rm -f "$1"
  fi
}

function configuredocker()
{
  if ! docker network inspect webhare-runkit > /dev/null 2>&1 ; then
    echo -n "Creating webhare-runkit network: "
    docker network create webhare-runkit --subnet=10.15.19.0/24
  fi
}

function applyborgsettings()
{
  local SETTINGSNAME
  SETTINGSNAME="$1"

  #TODO how risky is accept-new (in practice) ?
  export BORG_PRIVATEKEY=
  export BORG_REPO=
  export BORG_PASSPHRASE=

  if [ "$(type -t runkit_getborgsettings || true)" != "function" ] || ! runkit_getborgsettings "$SETTINGSNAME" ; then
    BORGSETTINGSFILE="$WEBHARE_RUNKIT_ROOT/local/$SETTINGSNAME.borg"
    if [ ! -f "$BORGSETTINGSFILE" ]; then
      echo Cannot locate expected settings file at "$BORGSETTINGSFILE"
      exit 1
    fi
    source "$BORGSETTINGSFILE"
  fi

  [ -n "$BORG_PRIVATEKEY" ] || ( echo "BORG_PRIVATEKEY not set" && exit 1 )
  [ -n "$BORG_REPO" ] || ( echo "BORG_REPO not set" && exit 1 )
  [ -n "$BORG_PASSPHRASE" ] || ( echo "BORG_PASSPHRASE not set" && exit 1 )

  # TODO is there a way to not persist the privatesshkey ? and avoiding ssh-agent which comes with its own persisting process problems ?
  SAVEUMASK=$(umask)
  WEBHARE_RUNKIT_KEYFILE="$(mktemp)"
  umask 077
  echo "$BORG_PRIVATEKEY" > "$WEBHARE_RUNKIT_KEYFILE"
  umask "$SAVEUMASK"

  export BORG_RSH="ssh -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes -i $WEBHARE_RUNKIT_KEYFILE"
}
