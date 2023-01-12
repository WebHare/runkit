#!/bin/bash

# short: List linked projects
mkdir -p "$WHRUNKIT_DATADIR"/_settings/projectlinks

for P in $(find "$WHRUNKIT_DATADIR"/_settings/projectlinks -type l) ; do
  echo "${P##*/} => $(readlink "$P")";
done
