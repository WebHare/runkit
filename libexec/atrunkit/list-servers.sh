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
    cat << HERE
      { "server": $(jq --raw-input <<<"$SERVER")
      , "containerImage": $(jq --raw-input <<<"$CONTAINERIMAGE")
      , "basePort": ${BASEPORT:-null}
      , "dataRoot": $(jq --raw-input <<<"$DATAROOT")
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
