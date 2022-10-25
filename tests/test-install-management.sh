#!/bin/bash

set -eo pipefail
source "${BASH_SOURCE%/*}/preptests.sh"


echo - Verify no installations yet
[ "$(( $(runkit list-servers 2>/dev/null | wc -w) ))" == "0" ] || fail "Number of installations should be 0, runkit ignored environment settings"

echo - Add an installation
runkit create-server --primary mywebhare

