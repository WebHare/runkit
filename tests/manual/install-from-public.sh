#!/bin/bash

set -eo pipefail

TESTOUTPUTROOT="$(mktemp -d /tmp/rk.installfrompublic.XXXXXXXXXXXX)"
echo "Test dir: $TESTOUTPUTROOT"
echo ""
echo "Running curl|bash isnstall"

export WHRUNKIT_INSTALLTO="$TESTOUTPUTROOT/runkit"
# prevent clobbering .bashrc
export WHRUNKIT_INSTALLBASHRC="$TESTOUTPUTROOT/bashrc"

curl https://gitlab.com/webhare/runkit/-/raw/main/install.sh | bash
