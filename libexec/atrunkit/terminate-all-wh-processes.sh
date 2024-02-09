#!/bin/bash
# short: Terminate all running WebHare related processes
# syntax: [ --kill ]

[[ "$OSTYPE" != "darwin"* ]] && die "Not implemented for $OSTYPE yet"

SIGNAL="SIGTERM"

exit_syntax()
{
  echo "Syntax: runkit terminate-all-wh-process [--kill]"
  echo "  --kill  Send a SIGKILL, not SIGTERM"
  exit 1
}

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [ "$1" == "--kill" ]; then
    SIGNAL="SIGKILL"
    shift
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

[ -z "$1" ] || exit_syntax

# shellcheck disable=SC2009 # no we can't use pgrep
PROCS="$(ps ewwax | grep ' [W]EBHARE_SERVICEMANAGERID=' | sed -r 's/^([^.]+).*$/\1/; s/^[^0-9]*([0-9]+).*$/\1/')"
[ -n "$PROCS" ] || die No WebHare processes found
# shellcheck disable=SC2046  # we need separate arguments
kill -s "$SIGNAL" $PROCS
