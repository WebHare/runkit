#!/bin/bash

WEBHARE_RUNKIT_ROOT="$(cd ${BASH_SOURCE%/*}/.. ; pwd )"
SSH_AGENT_PID=""

onexit()
{
  rv=$? #Make sure we don't destroy the exit code
  [ -n "$SSH_AGENT_PID" ] && kill $SSH_AGENT_PID
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

  BORGSETTINGSFILE="$WEBHARE_RUNKIT_ROOT/local/$SETTINGSNAME.borg"
  if [ ! -f "$BORGSETTINGSFILE" ]; then
    echo Cannot locate expected settings file at "$BORGSETTINGSFILE"
    exit 1
  fi

  #TODO how risky is accept-new (in practice) ?
  export BORG_RSH="ssh -o StrictHostKeyChecking=accept-new"
  export BORG_PRIVATEKEY=
  export BORG_REPO=
  export BORG_PASSPHRASE=

  source $BORGSETTINGSFILE
  [ -n "$BORG_PRIVATEKEY" ] || ( echo "BORG_PRIVATEKEY not set" && exit 1 )
  [ -n "$BORG_REPO" ] || ( echo "BORG_REPO not set" && exit 1 )
  [ -n "$BORG_PASSPHRASE" ] || ( echo "BORG_PASSPHRASE not set" && exit 1 )
  eval $(ssh-agent -s)
  ssh-add - <<< "$BORG_PRIVATEKEY"
}
