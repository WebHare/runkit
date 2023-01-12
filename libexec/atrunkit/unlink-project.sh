#!/bin/bash

# syntax: <projectname>
# short: Remove a link to the specified project

PROJECT="${1##/*}"
rm -f "$WHRUNKIT_DATADIR/_settings/projectlinks/$PROJECT"
