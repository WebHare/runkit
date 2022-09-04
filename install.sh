#!/bin/bash
set -e
[ -n "$WHRUNKIT_INSTALLTO" ] || WHRUNKIT_INSTALLTO="$HOME/webhare-runkit"

if ! hash git 2>/dev/null ; then
  echo Installing git..
  apt-get update
  apt-get install git
fi

if [ ! -d "$WHRUNKIT_INSTALLTO" ]; then
  echo "Cloning runkit to $WHRUNKIT_INSTALLTO"
  git clone https://gitlab.com/webhare/runkit.git "$WHRUNKIT_INSTALLTO"
fi

if ! grep -q '# webhare-runkit setup' "$HOME/.bashrc" 2>/dev/null ; then
  echo "eval \$(\"${WHRUNKIT_INSTALLTO}/bin/runkit\" setupmyshell) # webhare-runkit setup" >> "$HOME/.bashrc"
fi
