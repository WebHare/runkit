#!/bin/bash

WEBHARE_RUNKIT_ROOT="$(cd ${BASH_SOURCE%/*}/.. ; pwd )"
WHRUNKIT_ROOT="$WEBHARE_RUNKIT_ROOT"

if [ -z "$WHRUNKIT_ROOT" ]; then
   echo "Unable to find our root directory" 1>&2
   exit 1
fi

WEBHARE_RUNKIT_KEYFILE=""

if [ -z "$WHRUNKIT_DATADIR" ]; then
  if [ "$EUID" == "0" ]; then
    WHRUNKIT_DATADIR="/opt/whrunkit/"
  else
    WHRUNKIT_DATADIR="$HOME/whrunkit/"
  fi
fi

export WHRUNKIT_DATADIR WHRUNKIT_ROOT

onexit()
{
  rv=$? #Make sure we don't destroy the exit code
  [ -n "$WEBHARE_RUNKIT_KEYFILE" ] && rm "$WEBHARE_RUNKIT_KEYFILE"
  exit $rv
}

trap onexit EXIT

function die()
{
  echo "$@"
  exit 1
}

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

  WHRUNKIT_TARGETSERVER="$1"

  if [ "$(type -t runkit_getborgsettings || true)" != "function" ] || ! runkit_getborgsettings "$SETTINGSNAME" ; then
    BORGSETTINGSFILE="$WEBHARE_RUNKIT_ROOT/local/$SETTINGSNAME.borg"
    if [ ! -f "$BORGSETTINGSFILE" ]; then
      echo Cannot locate expected settings file at "$BORGSETTINGSFILE"
      [ -n "$WHRUNKIT_ONMISSINGSETTINGS" ] && echo "$WHRUNKIT_ONMISSINGSETTINGS"
      exit 1
    fi
    source "$BORGSETTINGSFILE"
  fi

  #Note: runkit_borgsettings is specifically allowed (encouraged?) to update WHRUNKIT_TARGETSERVER

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
  loadtargetsettings
  mkdir -p "$WHRUNKIT_TARGETDIR"
}

function loadtargetsettings
{
  if [ -z "$WHRUNKIT_TARGETSERVER" ]; then
    echo "WHRUNKIT_TARGETSERVER must be set!"
    exit 1
  fi

  WHRUNKIT_TARGETDIR="$WHRUNKIT_DATADIR/$WHRUNKIT_TARGETSERVER"

  export WEBHARE_INITIALDB=postgresql #will soon be obsolete, if not already
  WEBHARE_BASEPORT="$(cat "$WHRUNKIT_TARGETDIR/baseport")"
  WEBHARE_DATAROOT="$(cat "$WHRUNKIT_TARGETDIR/dataroot" 2>/dev/null)"
  if [ -z "$WEBHARE_DATAROOT" ] && [ -d "$WHRUNKIT_TARGETDIR/whdata" ]; then
     WEBHARE_DATAROOT="$WHRUNKIT_TARGETDIR/whdata"
   fi

  export WEBHARE_BASEPORT WEBHARE_DATAROOT
}

function download_backup()
{
  local RESTOREARCHIVE RESTORETO
  RESTOREARCHIVE="$1"

  if [ -z "$RESTOREARCHIVE" ]; then
    RESTOREARCHIVE="$(borg list --short --last 1)"
    [ -z "$RESTOREARCHIVE" ] && echo "No archive found!" && exit 1
    echo "Restoring archive $RESTOREARCHIVE"
  else
    # borg will print error messages to stderr (like "Archive ... does not exist")
    borg info "::$RESTOREARCHIVE" > /dev/null || exit 1
  fi

  # FIXME this only applies for webhare restores, we need a more generic 'hey, you're overwriting an earlier restore!'' thing..
  if [ -d "$WHRUNKIT_TARGETSERVER/whdata" ]; then
    echo "Target directory $RESTORETO/whdata already exists!"
    exit 1
  fi


  echo "$RESTOREARCHIVE" > "$WHRUNKIT_TARGETDIR/restore.archive" #FIXME also apply to webhare.restore file
  echo "$BORG_REPO" > "$WHRUNKIT_TARGETDIR/restore.borgrepo"

  # remove any existing restore directory
  RESTORETO="$WHRUNKIT_TARGETDIR/incomingrestore"

  [ -d "$RESTORETO" ] && rm -rf "$RESTORETO"
  mkdir -p "$RESTORETO"
  cd "$RESTORETO"
  borg extract "${BORGOPTIONS[@]}" "::$RESTOREARCHIVE" $BORGPATHS
  cd ..
  return 0
}

function validate_servername()
{
  # NOTE: what more characters to allow? at least not '.' or '@' to prevent future ambiguity with metadata or remote server names
  if ! [[ $1 =~ ^[-a-z0-9]+$ ]]; then
    echo "Invalid server name '$1'" 1>&2
    exit 1
  fi
}
