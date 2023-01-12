#!/bin/bash

# short: Get the WebHare source code

set -e #fail on any uncaught error

BRANCH="master"

load_forgeroot
REPOSITORY="${WHRUNKIT_FORGEROOT}platform.git"

exit_syntax()
{
  echo "Syntax: runkit get-webhare-source [options] [destdir]"
  echo "  --repository <repository>: set repository to use (default: $REPOSITORY)"
  echo "  --branch <branch>: set branch to check out (default: $BRANCH)"
  exit 1
}

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [ "$1" == "--branch" ]; then
    shift
    BRANCH="$1"
    shift
  elif [ "$1" == "--repository" ]; then
    shift
    REPOSITORY="$1"
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

git clone -b "$BRANCH" "$REPOSITORY" "$CHECKOUT_TO"
CHECKOUT_TO="$( cd "$CHECKOUT_TO" && pwd )"

if [ ! -f "$WHRUNKIT_DATADIR/_settings/sourceroot" ]; then
  echo "$CHECKOUT_TO" > "$WHRUNKIT_DATADIR/_settings/sourceroot"
fi

# Store a pointer so we can find the source again at some point. We don't have any APIs that use this info yet though!
CHECKOUTINFODIR="$WHRUNKIT_DATADIR/_settings/sourcecheckouts/$(date +%Y%m%dT%H%M%S)"
mkdir -p "$CHECKOUTINFODIR"
echo "$CHECKOUT_TO" > "$CHECKOUTINFODIR/sourceroot"

exit 0
