#!/bin/bash
# short: Open the web interface for this WebHare

open $("$WHRUNKIT_WHCOMMAND" dirs | grep "^Rescue port:" | cut -d: -f2-)
