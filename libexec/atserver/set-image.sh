#!/bin/bash
set -eo pipefail

exit_syntax()
{
  echo "Syntax: runkit @server set-image [--nopull] <imagename>"
  exit 1
}

NOPULL=
while true; do
  if [ "$1" == "--nopull" ]; then
    NOPULL="1"
    shift
  else
    break
  fi
done

SETIMAGE="$1"
shift

[ -n "$1" ] && exit_syntax
[ -z "$SETIMAGE" ] && exit_syntax

if [ -z "$NOPULL" ]; then
  podman pull "$SETIMAGE"
fi

# TODO check version compatibility ? check it's a webhare image?

echo "$SETIMAGE" > "$WHRUNKIT_TARGETDIR/container.image"
echo "Updated image to $SETIMAGE"
