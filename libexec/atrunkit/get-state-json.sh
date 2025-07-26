#!/bin/bash

set -e

# Describe the state of runkit on this host in JSON
(
  # host state structure version
  cat "$WHRUNKIT_ROOT"/version | jq --raw-input '{version: .}'
  date +"%Y-%m-%dT%H:%M:%S%z" | jq --raw-input "{date:.}"
  git -C "$WHRUNKIT_ROOT" rev-parse HEAD 2>/dev/null | jq --raw-input "{gitHash:.}"
  git -C "$WHRUNKIT_ROOT" status --porcelain=v2 --branch 2>/dev/null | jq --raw-input "{gitStatus:.}"

  # os version
  (cat /etc/redhat-release 2> /dev/null) | jq --raw-input "{os:.}"

  if [ -e /proc/meminfo ]; then
    (echo $(( ( $(< /proc/meminfo grep ^MemTotal:|grep -Eo "[0-9]*") + 1048575 ) /1048576 ))GB/"$(nproc)"c) | jq --raw-input "{specs:.}"
  fi
  if hash -r podman 2>/dev/null; then
    NON_CI_DOCKERS="$(comm -13 <(podman ps -q --filter=label=webharecitype=testdocker | sort) <(podman ps -q | sort))"
    if [ -n "$NON_CI_DOCKERS" ]; then
      # shellcheck disable=SC2086 # IDs are safely split here
      podman inspect $NON_CI_DOCKERS 2>/dev/null | jq "{containers:.}"
    fi
    podman stats --no-stream --format json | jq -s "{stats:.}"
  fi

  "$WHRUNKIT_ORIGCOMMAND" list-servers --json | jq '{servers:.}'
) | jq -s add
