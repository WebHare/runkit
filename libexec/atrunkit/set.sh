#!/bin/bash
# short: Set various runkit parameters

set -e #fail on any uncaught error

exit_syntax()
{
  echo "Syntax: runkit set forgeroot <newroot>"
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
    NEWROOT="$1"
    [ -n "$NEWROOT" ] || die "No new root specified"
    mkdir -p "$WHRUNKIT_DATADIR/_settings"
    echo "$NEWROOT" > "$WHRUNKIT_DATADIR/_settings/forgeroot"
    ;;
  *)
    echo "Unknown parameter"
    exit 1
    ;;
esac
