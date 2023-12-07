#!/bin/bash

# syntax: <projectdir>
# short: Setup a link to the specified project for use with whcd, whup, etc

[ -n "$1" ] || die "No directory specified"

TARGET=$(realpath "$1" 2>/dev/null)
[ -d "$TARGET" ] || die "No such directory: $1"
[ "${TARGET:0:1}" == "/" ] || die "realpath did not resolve to absolute path: $1 -> $TARGET"

PROJECT="${TARGET##/*}"
mkdir -p "$WHRUNKIT_DATADIR"/_settings/projectlinks
ln -sf "$TARGET" "$WHRUNKIT_DATADIR/_settings/projectlinks/$PROJECT"
