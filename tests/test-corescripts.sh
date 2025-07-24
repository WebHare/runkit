#!/bin/bash

set -eo pipefail
source "${BASH_SOURCE%/*}/preptests.sh"

VERSION=$(runkit version --json | jq -r '.runkitVersion')
if [ -z "$VERSION" ] || ! [[ "$VERSION" = "1."* ]]; then
  echo "invalid version: $VERSION"
  exit 1
fi
