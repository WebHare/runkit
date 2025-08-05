#!/bin/bash

# short: Update this runkit from the official runkit git repository

exit_syntax()
{
  cat << HERE
Syntax: runkit update [--force]
HERE
  echo " "
  exit 1
}

FORCE=0

while true; do
  if [ "$1" == "--force" ]; then
    shift
    FORCE=1
    shift
  elif [ "$1" == "--help" ]; then
    exit_syntax
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done


cd "$WHRUNKIT_ROOT" || exit 1

HTTPSORIGIN="https://gitlab.com/webhare/runkit.git"

if [ "$(git remote get-url https-origin 2>/dev/null)" != "$HTTPSORIGIN" ]; then
  echo Fix https-origin
  git remote remove https-origin 2>/dev/null
  git remote add https-origin $HTTPSORIGIN
fi


if [ -n "$(git status --porcelain)" ]; then
  if [ "$FORCE" == "1" ]; then
    git stash push --include-untracked --message "runkit update"
  else
    git status --porcelain
    echo "** clean up these changes first or invoke 'runkit update' with --force"
    exit 1
  fi
fi

git -c credential.helper= fetch https-origin

if ! git -c credential.helper= pull --quiet --ff-only --rebase https-origin main ; then
  echo "Update failed"
  exit 1
fi

echo "Runkit is now up-to-date"
exit 0
