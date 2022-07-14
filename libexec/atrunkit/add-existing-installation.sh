#!/bin/bash

# NOTE: what more charactesr to allow? at least not '.' or '@' to prevent future ambiguity with metadata or remote server names

TARGETSERVER="$1"
if ! [[ $TARGETSERVER =~ ^[-a-z0-9]+$ ]]; then
  echo Invalid name "$TARGETSERVER" 1>&2
  exit 1
fi

DATADIRECTORY="$(cd "$2" || exit 1 ; pwd)" #'pwd' ensures this path won't end with a /
if [ ! -d "$DATADIRECTORY/postgresql" ]; then
  echo "$DATADIRECTORY does not appear to be a WebHare installation (no postgresql database)" 2>&1
  exit 1
fi

SERVERCONFIGDIR="$WHRUNKIT_ROOT/local/$TARGETSERVER/"
if [ -d "$SERVERCONFIGDIR" ]; then
  echo "Installation $TARGETSERVER already exists" 2>&1
  exit 1
fi

for SERVER in $( cd "$WHRUNKIT_ROOT/local" ; echo * ); do
  if [ "$(cat "$WHRUNKIT_ROOT/local/$SERVER/dataroot" 2>/dev/null)" == "$DATADIRECTORY" ]; then
    echo "Installation $SERVER already points to $DATADIRECTORY" 2>&1
    exit 1
  fi
done

mkdir -p "$SERVERCONFIGDIR"

echo "$DATADIRECTORY" > "$SERVERCONFIGDIR/dataroot"
# TODO check for conflicting port numbers, and always avoid the builtin 13679-13689 range
echo "$(( RANDOM / 10 * 10 + 20000 ))" > "$SERVERCONFIGDIR/baseport"
echo "Created metadata for WebHare server '$TARGETSERVER'"
