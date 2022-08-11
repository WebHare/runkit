#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  cat << HERE
Syntax: restore-webhare-data.sh [options] <containername>
        --restoreto dir        Restore to this directory
        --archive arc          Archive to restore (defaults to latest)
        --dbaseonly            Only restore the database backup
        --nodocker             Do not use docker to do the actualy restore
        --fast                 Restore only essential dta (modules and database, but eg. no output or logs)
        --skipdownload         Do not redownload the backup, go straight to the database restore step
HERE
  echo " "
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"
RESTOREOPTIONS=()
RESTORETO=""
SKIPDOWNLOAD=""
NODOCKER=""
DOCKERIMAGE=""
FAST=""

while true; do
  if [ "$1" == "--restoreto" ]; then
    shift
    RESTORETO="$1"
    RESTOREOPTIONS+=("--restoreto" "$1")
    shift
  elif [ "$1" == "--archive" ]; then
    shift
    RESTOREOPTIONS+=("--archive" "$1")
    shift
  elif [ "$1" == "--dbaseonly" ]; then
    shift
    RESTOREOPTIONS+=("--dbaseonly")
  elif [ "$1" == "--skipdownload" ]; then
    SKIPDOWNLOAD="1"
    shift
  elif [ "$1" == "--nodocker" ]; then #do not use docker to restore webhare
    NODOCKER="1"
    shift
  elif [ "$1" == "--fast" ]; then
    FAST="1"
    shift
  elif [ "$1" == "--dockerimage" ]; then
    shift
    DOCKERIMAGE="$1"
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
[ -z "$CONTAINER" ] && exit_syntax
[ -z "$NODOCKER" ] && ensurecommands docker

if [ -n "$FAST" ]; then
  RESTOREOPTIONS+=("--dbaseonly" --exclude "*/whdata/output/*" --exclude "*/whdata/log/*")
fi
# Note: STATEDIR is legacy (When runkit was just for backups) and SERVERCONFIGDIR is for `runkit ...` commands
SERVERCONFIGDIR="$WHRUNKIT_ROOT/local/$CONTAINER/"

if [ -z "$RESTORETO" ]; then
  RESTORETO="${WEBHARE_RUNKIT_RESTORETO:-/containerstorage}/$CONTAINER"
fi

mkdir -p "$RESTORETO"
cd "$RESTORETO"

if [ -z "$SKIPDOWNLOAD" ]; then
  "$WEBHARE_RUNKIT_ROOT"/bin/restore-backup.sh "${RESTOREOPTIONS[@]}" "$CONTAINER"
fi

if [ ! -d whdata ]; then #whdata is deeper than expected, move it into place
  WHDATAFOLDER="$(find incomingrestore -name whdata -print -quit)"
  if [ -z "$WHDATAFOLDER" ] || ! [ -d "$WHDATAFOLDER/preparedbackup" ]; then
    echo "Cannot find the 'whdata' folder inside the backup, cannot continue the restore"
    exit 1
  fi

  if [ -d "$WHDATAFOLDER/local" ]; then
    mv "$WHDATAFOLDER/local" "$WHDATAFOLDER/local.bak.$(date +%Y%m%d-%H%M%S)"
  fi

  mv "$WHDATAFOLDER" ./whdata
fi

# TODO use the last STABLE branch, not master!
echo "WebHare data downloaded to $(cd whdata; pwd)"
mkdir -p "$SERVERCONFIGDIR"
echo "$PWD/whdata" > "$SERVERCONFIGDIR/dataroot"
[ -f "$SERVERCONFIGDIR/baseport" ] || echo "$(( RANDOM / 10 * 10 + 20000 ))" > "$SERVERCONFIGDIR/baseport"

if [ ! -d "$RESTORETO/whdata/dbase" ] && [ ! -d "$RESTORETO/whdata/postgresql" ]; then
  if [ -z "$DOCKERIMAGE" ]; then
    DOCKERIMAGE=webhare/platform:master
    if [ -f "$RESTORETO/whdata/preparedbackup/backup/backup.bk000" ]; then # dbserver backup
      DOCKERIMAGE=webhare/platform:release-4-35
      echo "Using docker image $DOCKERIMAGE because this is a dbserver backup"

      # auto-launch with 4.35
      if [ ! -f "$WEBHARE_RUNKIT_ROOT/local/$CONTAINER.dockerimage" ]; then
        echo "$DOCKERIMAGE" > "$WEBHARE_RUNKIT_ROOT/local/$CONTAINER.dockerimage"
      fi
    fi
  fi
  if [ -z "$NODOCKER" ]; then
    echo ".. now restoring database files from $RESTORETO/whdata/preparedbackup"
    docker run --rm -i -v "$RESTORETO/whdata:/opt/whdata" "$DOCKERIMAGE" wh restore --hardlink /opt/whdata/preparedbackup
  else
    if ! hash wh 2>/dev/null ; then
      echo "'wh' command not found, but needed for a --nodocker restore!"
      exit 1
    fi
    WEBHARE_DATAROOT="$RESTORETO/whdata/" wh restore "$RESTORETO/whdata/preparedbackup"
  fi
fi
