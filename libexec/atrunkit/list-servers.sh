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
  BASEPORT="$(cat "$WHRUNKIT_DATADIR/$SERVER/baseport" 2>/dev/null)"
  if [ -z $BASEPORT ]; then
    continue
  fi

  DEFAULTINFO=""
  if [ "$BASEPORT" == "13679" ]; then
    DEFAULTINFO="(default)"
  fi
  echo "$(right_pad $SERVER) $BASEPORT $DEFAULTINFO"
  ANY="1"
done

if [ -z "$ANY" ]; then
  echo No servers appear to be installed
  exit 1
fi

exit 0
