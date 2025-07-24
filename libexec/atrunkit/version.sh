#!/bin/bash

set -eo pipefail

exit_syntax()
{
  echo "Syntax: runkit version [--json]"
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

if [ -n "$JSON" ]; then
  cat << HERE
{
  "runkitVersion": "$(cat "$WHRUNKIT_ROOT"/version)",
  "gitHash": "$( (cd "$WHRUNKIT_ROOT" && git rev-parse HEAD) 2>/dev/null)"
}
HERE
  exit 0
fi

echo "runkit v$(cat "$WHRUNKIT_ROOT/version") running in $WHRUNKIT_ROOT"
