#!/bin/bash
# short: Lists WebHare servers configured in runkit

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

ANY=""
for SERVER in $( cd "$WHRUNKIT_DATADIR" ; echo * | sort); do
  TARGETDIR="$WHRUNKIT_DATADIR/$SERVER"
  BASEPORT="$(cat "$TARGETDIR/baseport" 2>/dev/null)"
  if [ -z $BASEPORT ]; then
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

  echo "$(right_pad $SERVER) $(right_pad "$BASEPORT $DEFAULTINFO") $DATAROOT"
  ANY="1"
done

if [ -z "$ANY" ]; then
  echo No servers appear to be installed
  exit 1
fi

exit 0
