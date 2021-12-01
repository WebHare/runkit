#!/bin/bash
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
  if which apt 2>/dev/null ; then
    apt-get update
    INSTALL="apt-get install -f -y --no-install-recommends"
    return
  else
    echo "Unknown packager"
    exit 1
  fi
}

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
  addpackage borgbackup
fi

if ! hash docker 2>/dev/null ; then
  echo Need to install docker
  addpackage docker.io
fi

if [ -n "$INSTALLPACKAGES" ]; then
  $INSTALL $INSTALLPACKAGES
fi
