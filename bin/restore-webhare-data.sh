#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  cat << HERE
Syntax: restore-webhare-data.sh [options] <containername>
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
SKIPDOWNLOAD=""
NODOCKER=""
DOCKERIMAGE=""
FAST=""
RESTOREARCHIVE=""

while true; do
  if [ "$1" == "--archive" ]; then
    shift
    RESTOREARCHIVE="$1"
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

applyborgsettings "$CONTAINER"

BORGOPTIONS=(--progress)
if [ -n "$FAST" ]; then
  BORGOPTIONS+=(--exclude "*/whdata/output/*" --exclude "*/whdata/log/*")
fi

if [ -z "$SKIPDOWNLOAD" ]; then
  download_backup "$RESTOREARCHIVE"
fi

if [ ! -d "$WHRUNKIT_TARGETDIR/whdata" ]; then #whdata is deeper than expected, move it into place
  WHDATAFOLDER="$(find "$WHRUNKIT_TARGETDIR/incomingrestore" -name whdata -print -quit)"
  if [ -z "$WHDATAFOLDER" ] || ! [ -d "$WHDATAFOLDER/preparedbackup" ]; then
    echo "Cannot find the 'whdata' folder inside the backup $WHRUNKIT_TARGETDIR/incomingrestore, cannot continue the restore"
    exit 1
  fi

  if [ -d "$WHDATAFOLDER/local" ]; then #FIXME document what exactly uses this - who stores into local/ ? is it documented?
    mv "$WHDATAFOLDER/local" "$WHDATAFOLDER/local.bak.$(date +%Y%m%d-%H%M%S)"
  fi

  mv "$WHDATAFOLDER" "$WHRUNKIT_TARGETDIR/whdata"
fi

# TODO use the last STABLE branch, not master!
echo "WebHare data downloaded to $WHRUNKIT_TARGETDIR/whdata"
echo "$PWD/whdata" > "$WHRUNKIT_TARGETDIR/dataroot"
[ -f "$WHRUNKIT_TARGETDIR/baseport" ] || echo "$(( RANDOM / 10 * 10 + 20000 ))" > "$WHRUNKIT_TARGETDIR/baseport"

if [ ! -d "$WHRUNKIT_TARGETDIR/whdata/dbase" ] && [ ! -d "$WHRUNKIT_TARGETDIR/whdata/postgresql" ]; then
  if [ -z "$DOCKERIMAGE" ]; then
    DOCKERIMAGE=webhare/platform:master
    if [ -f "$WHRUNKIT_TARGETDIR/whdata/preparedbackup/backup/backup.bk000" ]; then # dbserver backup
      DOCKERIMAGE=webhare/platform:release-4-35
      echo "Using docker image $DOCKERIMAGE because this is a dbserver backup"
    fi
  fi

  if [ ! -f "$WHRUNKIT_TARGETDIR/dockerimage" ]; then
    echo "$DOCKERIMAGE" > "$WHRUNKIT_TARGETDIR/dockerimage"
  fi

  if [ -z "$NODOCKER" ]; then
    echo ".. now restoring database files from $WHRUNKIT_TARGETDIR/whdata/preparedbackup"
    docker run --rm -i -v "$WHRUNKIT_TARGETDIR/whdata:/opt/whdata" "$DOCKERIMAGE" wh restore --hardlink /opt/whdata/preparedbackup
  else
    if ! hash wh 2>/dev/null ; then
      echo "'wh' command not found, but needed for a --nodocker restore!"
      exit 1
    fi
    WEBHARE_DATAROOT="$WHRUNKIT_TARGETDIR/whdata/" wh restore "$WHRUNKIT_TARGETDIR/whdata/preparedbackup"
  fi
fi
