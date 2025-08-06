#!/bin/bash

# short: Get all supporting WebHare open source code

set -eo pipefail

SUPPORTING_PROJECTS="proxy"
get_runkit_var WHRUNKIT_FORGEROOT forgeroot

exit_syntax()
{
  echo "Syntax: runkit download-support-source [--dryrun] [--projects <projects>] [destdir]"
  exit 1
}

DRYRUN=""
while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [ "$1" == "--dryrun" ]; then
    DRYRUN="1"
    shift
  elif [ "$1" == "--projects" ]; then
    shift
    SUPPORTING_PROJECTS="$1"
    shift
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

CHECKOUT_BASEDIR="${1}"
[ -n "$CHECKOUT_BASEDIR" ] || CHECKOUT_BASEDIR="$WHRUNKIT_PROJECTS"
mkdir -p "$CHECKOUT_BASEDIR"
mkdir -p "$WHRUNKIT_DATADIR"/_settings/projectlinks

touch "$CHECKOUT_BASEDIR"/.test-checkout || die "No write access to $CHECKOUT_BASEDIR"
rm "$CHECKOUT_BASEDIR"/.test-checkout

for PROJECT in $SUPPORTING_PROJECTS ; do
  PROJECTNAME="$(basename "$PROJECT")"
  REPOSITORY="${WHRUNKIT_FORGEROOT}${PROJECT}.git"
  TARGET="$CHECKOUT_BASEDIR"/"$PROJECTNAME"
  if [ -d "$TARGET" ]; then
    echo Not checking out "'$PROJECT'", it already exists at "$TARGET"
  else
    echo Checkout "$REPOSITORY" to "$TARGET"

    if [ -z "$DRYRUN" ]; then
      git clone --recurse-submodules "$REPOSITORY" "$TARGET"
      ln -sf "$TARGET" "$WHRUNKIT_DATADIR/_settings/projectlinks/$PROJECTNAME"
    fi
  fi
done

exit 0
