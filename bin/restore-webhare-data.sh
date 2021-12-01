#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: restore-webhare-data.sh [--restoreto dir] [--nodocker] <containername>"
  exit 1
}

onexit()
{
  [ -n "$SSH_AGENT_PID" ] && kill $SSH_AGENT_PID
}

WEBHARE_RUNKIT_ROOT="${BASH_SOURCE%/*/*}"
RESTORETO=""
SKIPRESTORE=""
NODOCKER=""

while true; do
  if [ "$1" == "--restoreto" ]; then
    shift
    RESTORETO="$1"
    shift
  elif [ "$1" == "--skiprestore" ]; then #unsupported option that allows you to skip the 'borg' step
    SKIPRESTORE="1"
    shift
  elif [ "$1" == "--nodocker" ]; then #do not use docker to restore webhare
    NODOCKER="1"
    shift
  elif [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

CONTAINER="$1"

# Install dependencies
NEEDCOMMANDS="borg ssh-add"
if [ -z "$NODOCKER" ]; then
  NEEDCOMMANDS="$NEEDCOMMANDS docker"
fi

if ! hash $NEEDCOMMANDS 2>&1 ; then
  "$WEBHARE_RUNKIT_ROOT/bin/setup.sh"
fi

trap onexit EXIT

[ -z "$CONTAINER" ] && exit_syntax

if [ -z "$RESTORETO" ]; then
  RESTORETO="/containerstorage/$CONTAINER"
fi

mkdir -p "$RESTORETO"
cd "$RESTORETO"

if [ -z "$SKIPRESTORE" ]; then
  BORGSETTINGSFILE="$WEBHARE_RUNKIT_ROOT/local/$CONTAINER.borg"
  if [ ! -f "$BORGSETTINGSFILE" ]; then
    echo Cannot locate expected settings file "$BORGSETTINGSFILE"
    exit 1
  fi

  source $BORGSETTINGSFILE

  RESTOREARCHIVE="$(borg list --short --last 1)"
  [ -z "$RESTOREARCHIVE" ] && echo "No archive found!" && exit 1

  if [ -d "$RESTORETO/whdata" ]; then
    echo "Target directory $RESTORETO/whdata already exists!"
    exit 1
  fi

  # remove any existing restore directory
  [ -d incomingrestore ] && rm -rf incomingrestore
  mkdir incomingrestore
  cd incomingrestore
  borg extract --progress "::$RESTOREARCHIVE"  # note: without --progress its a bit faster to start
  cd ..
fi

if [ ! -d whdata ]; then #whdata is deeper than expected, move it into place
  WHDATAFOLDER="$(find incomingrestore -name whdata -print -quit)"
  if [ -z "$WHDATAFOLDER" ] || ! [ -d "$WHDATAFOLDER/preparedbackup" ]; then
    echo "Cannot find the 'whdata' folder inside the backup, cannot continue the restore"
    exit 1
  fi

  mv "$WHDATAFOLDER" ./whdata
fi

# TODO use the last STABLE branch, not master!
echo "WebHare data downloaded to $(cd whdata; pwd)"

if [ ! -d "$RESTORETO/whdata/dbase" ] && [ ! -d "$RESTORETO/whdata/postgresql" ]; then
  if [ -z "$NODOCKER" ]; then
    echo ".. now restoring database files from $RESTORETO/whdata/preparedbackup"
    docker run --rm -ti -v "$RESTORETO/whdata:/opt/whdata" webhare/platform:master wh restore /opt/whdata/preparedbackup
  else
    if ! hash wh 2>/dev/null ; then
      echo "'wh' command not found, but needed for a --nodocker restore!"
      exit 1
    fi
    WEBHARE_DATAROOT="$RESTORETO/whdata/" wh restore "$RESTORETO/whdata/preparedbackup"
  fi
fi
