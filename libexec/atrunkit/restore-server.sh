#!/bin/bash
# syntax: <servername>
# short: Restore a WebHare server and create as a runkit installation

set -e #fail on any uncaught error

exit_syntax()
{
  cat << HERE
Syntax: runkit restore-server [options] <servername>
        --archive arc          Archive to restore (defaults to latest)
        --nodocker             Do not use docker to do the actualy restore
        --dockerimage <image>  Docker image to use for restore
        --fast                 Restore only essential dta (modules and database, but eg. no output or logs)
        --skipdownload         Do not redownload the backup, go straight to the database restore step
HERE
  echo " "
  exit 1
}

SKIPDOWNLOAD=""
NODOCKER=""
DOCKERIMAGE=""
FAST=""
RESTOREARCHIVE=""
BORGOPTIONS=(--progress)
VERBOSE=""

while true; do
  if [ "$1" == "--archive" ]; then
    shift
    RESTOREARCHIVE="$1"
    shift
  elif [ "$1" == "-v" ] || [ "$1" == "-verbose" ]; then
    VERBOSE="1"
    shift
  elif [ "$1" == "--skipdownload" ]; then
    SKIPDOWNLOAD="1"
    shift
  elif [ "$1" == "--nodocker" ]; then #do not use docker to restore webhare
    NODOCKER="1"
    shift
  elif [ "$1" == "--fast" ]; then
    FAST="1"
    shift
  elif [ "$1" == "--exclude" ]; then
    shift
    BORGOPTIONS+=(--exclude "$1")
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

resolve_whrunkit_command

# Figure out whether to use docker or the local runkit installation
if [ -z "$NODOCKER" ] && [ -z "$DOCKERIMAGE" ]; then
  if [ -x "$WHRUNKIT_WHCOMMAND" ]; then
    echo "nodocker/dockerimage not set - restoring using $WHRUNKIT_WHCOMMAND"
    NODOCKER=1
  else
    # TODO use the last STABLE branch, not master!
    DOCKERIMAGE="webhare/platform:master"
    echo "nodocker/dockerimage not set - using dockerimage $DOCKERIMAGE"
  fi
fi

[ -z "$NODOCKER" ] && ensurecommands docker

applyborgsettings "$CONTAINER"
# applyborgsettings also sets WHRUNKIT_TARGETSERVER and WHRUNKIT_TARGETDIR

validate_servername "$WHRUNKIT_TARGETSERVER"
ensure_server_baseport
loadtargetsettings

[ -n "$WEBHARE_DATAROOT" ] || die internal error, WEBHARE_DATAROOT not set

if [ -n "$FAST" ]; then
  BORGOPTIONS+=(--exclude "*/whdata/output/*" --exclude "*/whdata/log/*" --exclude "*/opt-whdata/output/*" --exclude "*/opt-whdata/log/*")
fi

if [ -d "$WEBHARE_DATAROOT/dbase" ] || [ -d "$WEBHARE_DATAROOT/postgresql" ]; then
  echo "A database already exists in $WEBHARE_DATAROOT/postgresql"
  exit 1
fi

DOWNLOADTO="$WEBHARE_DATAROOT/incomingbackup"
if [ -z "$SKIPDOWNLOAD" ]; then
  download_backup "$RESTOREARCHIVE" "$DOWNLOADTO"
fi

#whdata is ususally deeper than expected, move it into place
if [ ! -d "$WEBHARE_DATAROOT/preparedbackup" ]; then # Check if we didn't already move it int oplace..
  WHDATAFOLDER="$(find "$DOWNLOADTO" -name whdata -print -quit)"
  [ -z "$WHDATAFOLDER" ] && WHDATAFOLDER="$(find "$DOWNLOADTO" -name opt-whdata -print -quit)"
  if [ -z "$WHDATAFOLDER" ] || ! [ -d "$WHDATAFOLDER/preparedbackup" ]; then
    echo "Cannot find the 'whdata' folder inside the backup $DOWNLOADTO, cannot continue the restore"
    exit 1
  fi

  # if [ -d "$WHDATAFOLDER/local" ]; then #FIXME document what exactly uses this - who stores into local/ ? is it documented?
  #   mv "$WHDATAFOLDER/local" "$WHDATAFOLDER/local.bak.$(date +%Y%m%d-%H%M%S)"
  # fi

  # NOTE this way we rely on whdata not containing dot files that need restoring!.. fix it a bt without moving .. etc
  mv "$WHDATAFOLDER"/* "$WEBHARE_DATAROOT/"

  # Exclude the data of a restored server from backups
  createCacheDirTagFile "$WEBHARE_DATAROOT"
fi

mkdir -p "$WEBHARE_DATAROOT"
# download_backup also creates $WHRUNKIT_TARGETDIR/restore.archive and $WHRUNKIT_TARGETDIR/restore.archive
echo "Restoring container $WHRUNKIT_TARGETSERVER database to $WHEBARE_DATAROOT" > "$WEBHARE_DATAROOT"/webhare.restoremode
echo "Restored $(cat "$WHRUNKIT_TARGETDIR/restore.archive") from $(cat "$WHRUNKIT_TARGETDIR/restore.borgrepo")" > "$WEBHARE_DATAROOT"/webhare.restoremode

if [ -n "$NODOCKER" ]; then
  ensure_whrunkit_command
  [ -f "$WHRUNKIT_TARGETDIR/docker.image" ] && rm -f "$WHRUNKIT_TARGETDIR/docker.image"

  "$WHRUNKIT_WHCOMMAND" restore "$WEBHARE_DATAROOT/preparedbackup"
  echo ""
  echo "Container appears succesfully restored - launch it directly using: runkit @$WHRUNKIT_TARGETSERVER wh console"
  exit 0
else
  if [ "$DOCKERIMAGE" == "webhare/platform:master" ] && [ -f "$WHRUNKIT_TARGETDIR/whdata/preparedbackup/backup/backup.bk000" ]; then # dbserver backup
    DOCKERIMAGE=webhare/platform:release-4-35
    echo "Using docker image $DOCKERIMAGE because this is a dbserver backup"
  fi
  echo "$DOCKERIMAGE" > "$WHRUNKIT_TARGETDIR/docker.image"

  docker run --rm -i -v "$WEBHARE_DATAROOT:/opt/whdata" "$DOCKERIMAGE" wh restore --hardlink /opt/whdata/preparedbackup
  echo "Container appears succesfully restored"
fi
