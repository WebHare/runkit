#!/bin/bash
# short: Lists WebHare servers configured in runkit

set -eo pipefail

exit_syntax()
{
  echo "Syntax: runkit list-servers [--json]"
  exit 1
}

JSON=""

while true; do
  if [ "$1" == "--json" ]; then
    JSON="1"
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

[ -n "$1" ] && exit_syntax

right_pad()
{
  PAD="                       "
  if [ "${#1}" -gt "${#PAD}" ]; then
    PAD=""
  else
    PAD="${PAD:${#1}}"
  fi
  echo "$1$PAD"
}

function list_servers()
{
  ANY=""

  for SERVER in $( cd "$WHRUNKIT_DATADIR" ; echo * | sort); do
    TARGETDIR="$WHRUNKIT_DATADIR/$SERVER"
    set_from_file BASEPORT "$TARGETDIR/baseport"
    set_from_file CONTAINERIMAGE "$TARGETDIR/container.requestedimage"
    [ -z "$CONTAINERIMAGE" ] && set_from_file  CONTAINERIMAGE "$TARGETDIR/container.image" # fallback to pre 1.2.1 file
    set_from_file RESTORE_ARCHIVE "$TARGETDIR/restore.archive"
    set_from_file RESTORE_BORGREPO "$TARGETDIR/restore.borgrepo"
    set_from_file RESTORE_DATE "$TARGETDIR/restore.date"
    set_from_file CONTAINER_OPTIONS "$TARGETDIR/container-options"
    set_from_file DOCKER_OPTIONS "$TARGETDIR/docker-options" # to see which server still have 'old' options files
    set_from_file REQUIRED_UNITS "$TARGETDIR/required-units"

    if [ -z $BASEPORT ] && [ -z "$CONTAINERIMAGE" ]; then
      continue
    fi

    DEFAULTINFO=""
    if [ "$BASEPORT" == "13679" ]; then
      DEFAULTINFO="(default)"
    fi

    DATAROOT="$(cat "$TARGETDIR/dataroot" 2>/dev/null || true)"
    [ -z "$DATAROOT" ] && DATAROOT="$TARGETDIR/whdata"

    # Subst $HOME with ~
    if [ "${DATAROOT::${#HOME}}" == "$HOME" ]; then
      DATAROOT="~${DATAROOT:${#HOME}}"
    fi

    if [ -z "$ANY" ]; then
      ANY=1
    elif [ -n "$JSON" ]; then
      echo ","
    fi

    if [ -n "$JSON" ]; then
      # jq -R -s '@text' ensures escaping and newlines if needed
    cat << HERE
      { "server": $(echo -n "$SERVER" | jq -R -s '@text')
      , "containerImage": $(echo -n "$CONTAINERIMAGE" | jq -R -s '@text')
      , "basePort": ${BASEPORT:-null}
      , "dataRoot": $(echo -n "$DATAROOT" | jq -R -s '@text' )
      , "restoreArchive": $(echo -n "$RESTORE_ARCHIVE" | jq -R -s '@text' )
      , "restoreBorgRepo": $(echo -n "$RESTORE_BORGREPO" | jq -R -s '@text' )
      , "restoreDate": $(echo -n "$RESTORE_DATE" | jq -R -s '@text' )
      , "containerOptions": $(echo -n "$CONTAINER_OPTIONS" | jq -R -s '@text' )
      , "dockerOptions": $(echo -n "$DOCKER_OPTIONS" | jq -R -s '@text' )
      , "requiredUnits": $(echo -n "$REQUIRED_UNITS" | jq -R -s '@text' )
      }
HERE
    else
      echo "$(right_pad $SERVER) $(right_pad "${CONTAINERIMAGE:-$BASEPORT $DEFAULTINFO}") $DATAROOT"
    fi
  done

  [ -z "$ANY" ]  && [ -z "$JSON" ] && echo "No servers appear to be installed" >&2
}

if [ -n "$JSON" ]; then
  echo "[ $(list_servers) ]"  | jq
else
  list_servers
fi

exit 0
