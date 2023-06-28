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
  CONTAINERIMAGE="$(cat "$TARGETDIR/container.image" 2>/dev/null)"
  if [ -z $BASEPORT ] && [ -z "$CONTAINERIMAGE" ]; then
    continue
  fi

  if [ "${CONTAINERIMAGE:0:27}" == "docker.io/webhare/platform:" ]; then
    CONTAINERIMAGE="${CONTAINERIMAGE:27}"
  fi
  if [ "${CONTAINERIMAGE:0:24}" == "docker.io/webhare/proxy:" ]; then
    CONTAINERIMAGE="${CONTAINERIMAGE:24}"
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

  echo "$(right_pad $SERVER) $(right_pad "${CONTAINERIMAGE:-$BASEPORT $DEFAULTINFO}") $DATAROOT"
  ANY="1"
done

[ -z "$ANY" ] && die "No servers appear to be installed"

exit 0
