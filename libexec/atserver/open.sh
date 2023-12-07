#!/bin/bash
# short: Open the web interface for this WebHare
if [ "$1" != "" ]; then
  echo "Invalid syntax: just use runkit [@server] open"
  exit 1
fi

ensure_whrunkit_command
open $("$WHRUNKIT_WHCOMMAND" dirs | grep "^Rescue port:" | cut -d: -f2-)
