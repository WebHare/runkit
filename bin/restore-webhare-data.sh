#!/bin/bash
set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: restore-webhare-data.sh [--restoreto dir] [--backupsource source] [--nodocker] <containername>"
  exit 1
}

source "${BASH_SOURCE%/*}/../libexec/functions.sh"
RESTOREOPTIONS=()
RESTORETO=""
SKIPRESTORE=""
NODOCKER=""
BACKUPSOURCE=""

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
  elif [ "$1" == "--backupsource" ]; then #unsupported option that allows you to skip the 'borg' step
    shift
    BACKUPSOURCE="$1"
    RESTOREOPTIONS+=("--backupsource" "$BACKUPSOURCE")
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
[ -z "$CONTAINER" ] && exit_syntax
[ -z "$NODOCKER" ] && ensurecommands docker

if [ -z "$RESTORETO" ]; then
  RESTORETO="${WEBHARE_RUNKIT_RESTORETO:-/containerstorage}/$CONTAINER"
fi

mkdir -p "$RESTORETO"
cd "$RESTORETO"

if [ -z "$SKIPRESTORE" ]; then
  "$WEBHARE_RUNKIT_ROOT"/bin/restore-backup.sh "${RESTOREOPTIONS[@]}" "$CONTAINER"
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
    docker run --rm -i -v "$RESTORETO/whdata:/opt/whdata" webhare/platform:master wh restore --hardlink /opt/whdata/preparedbackup
  else
    if ! hash wh 2>/dev/null ; then
      echo "'wh' command not found, but needed for a --nodocker restore!"
      exit 1
    fi
    WEBHARE_DATAROOT="$RESTORETO/whdata/" wh restore "$RESTORETO/whdata/preparedbackup"
  fi
fi
