#!/bin/bash

set -eo pipefail
ROOTDIR="$(cd "${BASH_SOURCE%/*}/.." ; pwd)"
source "${BASH_SOURCE%/*}/preptests.sh"

if [ -z "$WHRUNKIT_DATADIR" ]; then
  echo "WHRUNKIT_DATADIR not set"
  exit 1
fi

cd "$ROOTDIR"
SCRIPTS=(./*.sh bin/*.sh libexec/*.sh libexec/*/*.sh)
# invoke twice, the second version will set an exit code if shellcheck finds error. TODO lower to warning or even lower!
./node_modules/.bin/shellcheck "${SCRIPTS[@]}" || ./node_modules/.bin/shellcheck -f quiet -S error "${SCRIPTS[@]}"
