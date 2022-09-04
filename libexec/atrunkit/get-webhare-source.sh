#!/bin/bash

# short: Get the WebHare source code

set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: runkit get-webhare-source [options] [destdir]"
  echo "  --branch <branch>: set branch to check out (default: master)"
  exit 1
}

BRANCH="master"

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [ "$1" == "--branch" ]; then
    shift
    BRANCH="$1"
    shift
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

mkdir -p "$WHRUNKIT_DATADIR/_settings"

CHECKOUT_TO="${1}"
[ -n "$CHECKOUT_TO" ] || CHECKOUT_TO="$(cat "$WHRUNKIT_DATADIR/_settings/sourceroot" 2>/dev/null || true)"
[ -n "$CHECKOUT_TO" ] || CHECKOUT_TO="$HOME/projects/webhare"

if [ -d "$CHECKOUT_TO" ]; then
  echo "Checkout directory $CHECKOUT_TO already exists"
  exit 1
fi

git clone -b "$BRANCH" https://gitlab.com/webhare/platform.git "$CHECKOUT_TO"
CHECKOUT_TO="$( cd "$CHECKOUT_TO" && pwd )"

if [ ! -f "$WHRUNKIT_DATADIR/_settings/sourceroot" ]; then
  ( cd "$CHECKOUT_TO" && pwd ) > "$WHRUNKIT_DATADIR/_settings/sourceroot"
fi

exit 0
