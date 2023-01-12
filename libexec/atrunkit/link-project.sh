#!/bin/bash

# syntax: <projectdir>
# short: Setup a link to the specified project for use with whcd, whup, etc

[ -d "$1" ] || die "No such directory: $1"
[ "${1:0:1}" == "/" ] || die "Must be absolute path: $1"

PROJECT="${1##/*}"
mkdir -p "$WHRUNKIT_DATADIR"/_settings/projectlinks
ln -sf "$1" "$WHRUNKIT_DATADIR/_settings/projectlinks/$PROJECT"
