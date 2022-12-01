#!/bin/bash
set -e
[ -n "$WHRUNKIT_INSTALLTO" ] || WHRUNKIT_INSTALLTO="$HOME/webhare-runkit"
[ -n "$WHRUNKIT_INSTALLBASHRC" ] || WHRUNKIT_INSTALLBASHRC="$HOME/.bashrc"

if ! hash git 2>/dev/null ; then
  echo Installing git..
  apt-get update -y
  apt-get install -y git || true
  if ! hash git 2>/dev/null ; then
    echo Looks like git installation failed
    exit 1
  fi
fi

if [ ! -d "$WHRUNKIT_INSTALLTO" ]; then
  echo "Cloning runkit to $WHRUNKIT_INSTALLTO"
  git clone https://gitlab.com/webhare/runkit.git "$WHRUNKIT_INSTALLTO"
fi

if ! grep -q '# webhare-runkit setup' "$WHRUNKIT_INSTALLBASHRC" 2>/dev/null ; then
  echo "eval \$(\"${WHRUNKIT_INSTALLTO}/bin/runkit\" setupmyshell) # webhare-runkit setup" >> "$WHRUNKIT_INSTALLBASHRC"
fi

echo "Completed runkit installation - relogin to apply shell settings"
