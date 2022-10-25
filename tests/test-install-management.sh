#!/bin/bash

set -eo pipefail
source "${BASH_SOURCE%/*}/preptests.sh"

mkdir -p "$WHRUNKIT_DATADIR/_settings"

if [ -n "$RUNKIT_CI_SOURCEDOWNLOAD" ]; then
  echo - Test with sourcecode download
  echo "$TESTOUTPUTROOT/source" > "$WHRUNKIT_DATADIR/_settings/sourceroot"
  runkit get-webhare-source
else
  # share source root then..
  cp "$HOME/whrunkit/_settings/sourceroot" "$WHRUNKIT_DATADIR/_settings/sourceroot"
fi

echo - Verify no installations yet
[ "$(( $(runkit list-servers 2>/dev/null | wc -w) ))" == "0" ] || fail "Number of installations should be 0, runkit ignored environment settings"

echo - Add primary installation
runkit create-server --primary mywebhare

# There's very little we can run without building a full webhare..
echo - Verify default installations
runkit @default wh isrunning || exitcode=$?
[ "$exitcode" == "1" ] || fail "Got unexpected exitcode $exitcode"

echo - Add additional installation
runkit create-server ci

echo - Verify additional installations
runkit @ci wh isrunning || exitcode=$?
[ "$exitcode" == "1" ] || fail "Got unexpected exitcode $exitcode"

exit 0
