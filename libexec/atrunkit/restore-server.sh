#!/bin/bash
# syntax: <servername>
# short: Restore a WebHare server and create as a runkit installation

set -e #fail on any uncaught error

exit_syntax()
{
  cat << HERE
Syntax: runkit restore-server [options] <servername>
        --archive arc          Archive to restore (defaults to latest)
        --nocontainer          Do not use a container to do the actualy restore
        --image <image>        Container image to use for restore. You MUST set this to 4.35 if you need to restore a 'dbserver' container
        --fast                 Restore only essential data (modules and database, but eg. no output or logs)
        --skipdownload         Do not redownload the backup, go straight to the database restore step
HERE
  echo " "
  exit 1
}

SKIPDOWNLOAD=""
NOCONTAINER=""
CONTAINER=""
SETIMAGE=""
FAST=""
RESTOREARCHIVE=""
BORGOPTIONS=(--progress)

while true; do
  if [ "$1" == "--archive" ]; then
    shift
    RESTOREARCHIVE="$1"
    shift
  elif [ "$1" == "--skipdownload" ]; then
    SKIPDOWNLOAD="1"
    shift
  elif [ "$1" == "--nodocker" ] || [ "$1" == "--nocontainer" ]; then #do not use a container to restore webhare
    NOCONTAINER="1"
    shift
  elif [ "$1" == "--container" ]; then #use a container but figure out image ourselves
    CONTAINER="1"
    shift
  elif [ "$1" == "--fast" ]; then
    FAST="1"
    shift
  elif [ "$1" == "--exclude" ]; then
    shift
    BORGOPTIONS+=(--exclude "$1")
    shift
  elif [ "$1" == "--image" ]; then
    shift
    SETIMAGE="$1"
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
applyborgsettings "$CONTAINER" #Implies validate_servername, loadtargetsettings, settargetdir

# Figure out whether to use a container or the local runkit installation
if [ -z "$NOCONTAINER" ] && [ -z "$SETIMAGE" ]; then
  if [ ! -f "$WHRUNKIT_TARGETDIR/container.image" ]; then # No image ever selected
    if [ -z "$CONTAINER" ] && [ -x "$WHRUNKIT_WHCOMMAND" ]; then
      echo "--nocontainer/--image not set - restoring using $WHRUNKIT_WHCOMMAND"
      NOCONTAINER=1
    else
      # TODO use the last STABLE branch, not main! Or allow/require caller to specify
      echo "--nocontainer/--image not set - selecting an image"
      SETIMAGE=main
    fi
  fi
fi

if [ -z "$NOCONTAINER" ]; then
  if [ -n "$SETIMAGE" ]; then
    configure_runkit_podman
    set_webhare_image "$SETIMAGE"
  fi
fi

# applyborgsettings also sets WHRUNKIT_TARGETSERVER and WHRUNKIT_TARGETDIR

[ -n "$NOCONTAINER" ] && ensure_server_baseport
loadtargetsettings

[ -n "$WEBHARE_DATAROOT" ] || die internal error, WEBHARE_DATAROOT not set

if [ -n "$FAST" ]; then
  BORGOPTIONS+=(--exclude "*/whdata/output/*" --exclude "*/whdata/log/*" --exclude "*/opt-whdata/output/*" --exclude "*/opt-whdata/log/*" --exclude "*/opt-whdata/log/*")
fi

if [ -d "$WEBHARE_DATAROOT/dbase" ] || [ -d "$WEBHARE_DATAROOT/postgresql" ]; then
  die "A database already exists in $WEBHARE_DATAROOT/postgresql"
fi

DOWNLOADTO="$WEBHARE_DATAROOT/incomingbackup"
if [ -z "$SKIPDOWNLOAD" ]; then
  download_backup "$RESTOREARCHIVE" "$DOWNLOADTO"
fi

#whdata is ususally deeper than expected, move it into place
RESTOREFROMDIR="$WEBHARE_DATAROOT/preparedbackup"

# WH before 5.5/5.6 contained a bug and may create 'whdata/preparedbackup' even if in rescue mode.
# This may be triggered whilst we are still restoring but a backup is attempted by eg cron
# As whdata/preparedbackup will be empty, just attempting to rmdir it always is an easy workaround
rmdir "$RESTOREFROMDIR" 2>/dev/null || true   #remove when WHs before 5.7 are irrelevant

if [ ! -d "$RESTOREFROMDIR" ]; then # Check if we didn't already move it into place..
  WHDATAFOLDER="$(find "$DOWNLOADTO" -name whdata -print -quit)"
  [ -z "$WHDATAFOLDER" ] && WHDATAFOLDER="$(find "$DOWNLOADTO" -name opt-whdata -print -quit)"
  if [ -z "$WHDATAFOLDER" ] || ! [ -d "$WHDATAFOLDER/preparedbackup" ]; then
    die "Cannot find the 'whdata' folder inside the backup $DOWNLOADTO, cannot continue the restore"
  fi

  if [ -e "$WHDATAFOLDER/incomingbackup" ]; then
    # This is a restore of an earlier restored server, and it still had a incomingbackup folder in its whdata
    # That will collide with the incomingbackup folder we just created, so rename it
    mv "$WHDATAFOLDER/incomingbackup" "$WHDATAFOLDER/incomingbackup.$(date "+%Y-%m-%dT%H:%M:%S")"
  fi

  # if [ -d "$WHDATAFOLDER/local" ]; then #FIXME document what exactly uses this - who stores into local/ ? is it documented?
  #   mv "$WHDATAFOLDER/local" "$WHDATAFOLDER/local.bak.$(date +%Y%m%d-%H%M%S)"
  # fi

  # NOTE this way we rely on whdata not containing dot files that need restoring!.. fix it a bt without moving .. etc
  mv "$WHDATAFOLDER"/* "$WEBHARE_DATAROOT/"

  # Exclude the data of a restored server from backups - TODO we can only do this if the user confirmed this is a temp backup! Not on remote servers! reevaluate criteria...
  # createCacheDirTagFile "$WEBHARE_DATAROOT"
fi

EXPECTFILE="$RESTOREFROMDIR/backup/base.tar.gz"
if [ ! -f "$EXPECTFILE" ]; then
  die "$RESTOREFROMDIR doesn't appear to contain a backup to restore, $EXPECTFILE is missing"
fi

mkdir -p "$WEBHARE_DATAROOT"
[ -f "$WEBHARE_DATAROOT"/webhare.restoredone ] && rm "$WEBHARE_DATAROOT"/webhare.restoredone #remove 'done' marker
# download_backup also creates $WHRUNKIT_TARGETDIR/restore.archive and $WHRUNKIT_TARGETDIR/restore.archive
echo "Restoring container $WHRUNKIT_TARGETSERVER database to $WEBHARE_DATAROOT" > "$WEBHARE_DATAROOT"/webhare.restoremode
echo "Restored $(cat "$WHRUNKIT_TARGETDIR/restore.archive") from $(cat "$WHRUNKIT_TARGETDIR/restore.borgrepo")" > "$WEBHARE_DATAROOT"/webhare.restoremode

if [ -n "$NOCONTAINER" ]; then
  ensure_whrunkit_command
  [ -f "$WHRUNKIT_TARGETDIR/container.image" ] && rm -f "$WHRUNKIT_TARGETDIR/container.image"

  "$WHRUNKIT_WHCOMMAND" restore "$RESTOREFROMDIR"
  date > "$WEBHARE_DATAROOT"/webhare.restoredone
  echo ""
  echo "Container appears succesfully restored - launch it directly using: runkit @$WHRUNKIT_TARGETSERVER wh console"
  exit 0
else
  # Mark restored volume as unshared
  podman run --rm -i -v "$WEBHARE_DATAROOT:/opt/whdata":Z "$WHRUNKIT_CONTAINERIMAGE" wh restore --hardlink /opt/whdata/preparedbackup

  date > "$WEBHARE_DATAROOT"/webhare.restoredone
  echo "Container appears succesfully restored"
fi
