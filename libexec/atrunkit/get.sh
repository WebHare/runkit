#!/bin/bash
# short: Get various runkit parameters

set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: runkit get forgeroot"
  exit 1
}

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

CMD="$1"
shift

case "$CMD" in
  forgeroot)
    load_forgeroot
    echo "$WHRUNKIT_FORGEROOT"
    ;;
  *)
    echo "Unknown parameter"
    exit 1
    ;;
esac
