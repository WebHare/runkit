#!/bin/bash
#short: install necessary Runkit dependencies

set -e

DIDPREPARE=""
INSTALLPACKAGES=""
INSTALL=""

function prepareinstall()
{
  if [ -n "$DIDPREPARE" ]; then
    return
  fi

  DIDPREPARE=1
  if hash apt 2>/dev/null ; then
    apt-get update
    INSTALL="apt-get install -f -y --no-install-recommends"
  elif hash dnf 2>/dev/null ; then
    INSTALL="dnf install -y"
  else
    echo "Unknown packager"
    exit 1
  fi
}

[ -f /etc/os-release ] && source /etc/os-release

function addpackage()
{
  prepareinstall
  INSTALLPACKAGES="$INSTALLPACKAGES $1"
}

if ! hash ssh-agent 2>/dev/null ; then
  echo Need to install ssh-agent
  addpackage openssh-client
fi

if ! hash borg 2>/dev/null ; then
  echo Need to install borg
  # Enable EPEL
  if grep -qE "^ID_LIKE=.*\brhel\b" /etc/os-release || grep -qE "^ID=rhel$" /etc/os-release ; then
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  fi
  addpackage borgbackup
fi

if ! hash podman 2>/dev/null ; then
  echo Need to install podman to manage containers
  addpackage podman
fi

if ! hash jq 2>/dev/null ; then
  echo Need to install jq
  addpackage jq
fi

if [ -n "$INSTALLPACKAGES" ]; then
  $INSTALL $INSTALLPACKAGES
fi
