#!/bin/bash

WEBHARE_RUNKIT_ROOT="$(cd ${BASH_SOURCE%/*}/.. ; pwd )"
SSH_AGENT_PID=""

onexit()
{
  [ -n "$SSH_AGENT_PID" ] && kill $SSH_AGENT_PID
}

trap onexit EXIT

function ensurecommands()
{
  if ! hash "$@" >/dev/null 2>&1 ; then
    "$WEBHARE_RUNKIT_ROOT/bin/setup.sh"
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

  #TODO how risky is it to fully disable this? is there usable alternative?
  SSHOPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  export BORG_RSH="ssh $SSHOPTS"
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
