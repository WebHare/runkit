#!/bin/bash
set -e
if [ -z "$WHRUNKIT_INSTALLTO" ]; then
  if [ "$(id -u)" == "0" ]; then #as root
    WHRUNKIT_INSTALLTO="/opt/webhare-runkit"
  else
    WHRUNKIT_INSTALLTO="$HOME/webhare-runkit"
  fi
fi

[ -n "$WHRUNKIT_INSTALLBASHRC" ] || WHRUNKIT_INSTALLBASHRC="$HOME/.bashrc"

if ! hash git 2>/dev/null ; then
  echo Installing git..
  if hash apt-get 2>/dev/null ; then
    apt-get update -y
    apt-get install -y git || true
  else
    dnf install -y git
  fi

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
