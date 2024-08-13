#!/bin/bash
# short: Set various runkit parameters

set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: runkit set forgeroot|networkprefix <newvalue>"
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
mkdir -p "$WHRUNKIT_DATADIR/_settings"

case "$CMD" in
  forgeroot)
    NEWROOT="$1"
    [ -n "$NEWROOT" ] || die "No new root specified"
    echo "$NEWROOT" > "$WHRUNKIT_DATADIR/_settings/forgeroot"
    ;;
  networkprefix)
    [ -n "$1" ] || die "No new prefix specified"
    echo "$1" > "$WHRUNKIT_DATADIR/_settings/networkprefix"
    ;;
  *)
    echo "Unknown parameter"
    exit 1
    ;;
esac
