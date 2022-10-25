#!/bin/bash

cd "${BASH_SOURCE%/*}/.."
TESTBASE="$PWD"
TESTOUTPUTROOT="$(mktemp -d)"

echo Testing runkit "$TESTBASE" in: "$TESTOUTPUTROOT"
mkdir -p "$TESTOUTPUTROOT"
export WHRUNKIT_DATADIR="$TESTOUTPUTROOT/whrunkit"

function fail()
{
  echo "Test failed: " "$@"
  exit 1
}
function runkit()
{
  "$TESTBASE/bin/runkit" "$@"
}
