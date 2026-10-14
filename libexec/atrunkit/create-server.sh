#!/bin/bash
# syntax: [--default] <servername>
# short: Configure a new server

function exit_syntax
{
  echo "Syntax: runkit create-server [--default] [--baseport <port>] [--source <sourcedir>] [--image <image>] <server>"
  echo "  --default           sets the baseport to 13679 and binds the server to the 'wh' alias"
  echo "  --source            override WebHare source tree to use"
  echo "  --image             install container using specified image"
  echo "  --whdata            set data dir"
  echo "  --use-devcontainer  use devcontainer for the server (with automatic source download when --source is not provided)"
  echo "    --repository      specify the repository to use when downloading the WebHare source (only with --use-devcontainer)"
  echo "    --branch          specify the branch to use when downloading the WebHare source (only with --use-devcontainer)"
  echo "    --make            run 'make install' inside the devcontainer after downloading the source (only with --use-devcontainer)"
  echo "  <server>            short name for the server, used as wh-<server> alias"
  exit 1
}

source "${BASH_SOURCE%/*}/__servercreation.sh" || die "cannot load function library"
SOURCEROOT=""
IMAGE=""
WHDATA=""
QUIET=""
DEVCONTAINER=""
RUNMAKE=""
REPOSITORY=""
BRANCH=""

while true; do
  if [ "$1" == "--default" ]; then
    shift
    PRIMARY="1"
  elif [ "$1" == "--baseport" ]; then
    shift
    BASEPORT="$1"
    shift
  elif [ "$1" == "--source" ]; then
    shift
    SOURCEROOT="$1"
    shift
  elif [ "$1" == "--image" ]; then
    shift
    IMAGE="$1"
    shift
  elif [ "$1" == "--whdata" ]; then
    shift
    WHDATA="$1"
    shift
  elif [ "$1" == "--recreate" ]; then
    RECREATE="1"
    shift
  elif [ "$1" == "--use-devcontainer" ]; then
    DEVCONTAINER="1"
    shift
  elif [ "$1" == "--make" ]; then
    RUNMAKE="1"
    shift
  elif [ "$1" == "--branch" ]; then
    shift
    BRANCH="$1"
    shift
  elif [ "$1" == "--repository" ]; then
    shift
    REPOSITORY="$1"
    shift
  elif [ "$1" == "--quiet" ]; then
    QUIET="1"
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

if [ "$RUNMAKE" == "1" ] && [ -z "$DEVCONTAINER" ]; then
  echo "The --make option can only be used with --use-devcontainer"
  exit 1
fi
if [ -n "$BRANCH" ] && { [ -z "$DEVCONTAINER" ] || [ -n "$SOURCEROOT" ]; }; then
  echo "The --branch option can only be used with --use-devcontainer without --source"
  exit 1
fi
if [ -n "$REPOSITORY" ] && { [ -z "$DEVCONTAINER" ] || [ -n "$SOURCEROOT" ]; }; then
  echo "The --repository option can only be used with --use-devcontainer without --source"
  exit 1
fi

WHRUNKIT_TARGETSERVER="$1"
[ -n "$WHRUNKIT_TARGETSERVER" ] || exit_syntax

# Check if a volume is needed, and that it does not already exist
VOLUME_WHDATA=""
if [ -z "$WHDATA" ] && [ -n "$DEVCONTAINER" ]; then
  # Ensure the named volume 'runkit-volume-${WHRUNKIT_TARGETSERVER}-whdata' does not exist yet
  VOLUME_WHDATA="runkit-volume-${WHRUNKIT_TARGETSERVER}-whdata"
  if podman volume exists "$VOLUME_WHDATA"; then
    echo "Volume $VOLUME_WHDATA already exists. If you are sure it needs to be removed, use podman volume rm \"$VOLUME_WHDATA\""
    exit 1
  fi
fi

prepare_newserver #aborts if server already exists

WEBHARE_DATAROOT=""

mkdir -p "$WHRUNKIT_TARGETDIR"
if [ -n "$WHDATA" ]; then
  echo "$WHDATA" > "$WHRUNKIT_TARGETDIR/dataroot"
elif [ -n "$DEVCONTAINER" ]; then
  [ -n "$VOLUME_WHDATA" ] || die "Expected VOLUME_WHDATA to be set"
  podman volume create "$VOLUME_WHDATA"
  echo "$VOLUME_WHDATA" > "$WHRUNKIT_TARGETDIR/dataroot"
else
  mkdir -p "$WHRUNKIT_TARGETDIR/whdata/installedmodules"
  rm -f "$WHRUNKIT_TARGETDIR/dataroot"
fi

if [ -n "$DEVCONTAINER" ]; then
  IMAGE=localhost/webhare/platform:devcontainer
  if [ -z "$SOURCEROOT" ]; then
    if ! [ -d "$WHRUNKIT_TARGETDIR/webhare" ]; then
      echo "No source tree specified, downloading WebHare source..."
      DOWNLOAD_OPTIONS=()
      if [ -n "$BRANCH" ]; then
        DOWNLOAD_OPTIONS+=(--branch "$BRANCH")
      fi
      if [ -n "$REPOSITORY" ]; then
        DOWNLOAD_OPTIONS+=(--repository "$REPOSITORY")
      fi
      # shellcheck source=download-webhare-source.sh
      ( source "${BASH_SOURCE%/*}/download-webhare-source.sh" "${DOWNLOAD_OPTIONS[@]}" "$WHRUNKIT_TARGETDIR/webhare" )
    fi
    SOURCEROOT="$WHRUNKIT_TARGETDIR/webhare"
  fi
  if ! podman image exists "$IMAGE"; then
    echo "Devcontainer does not exist yet, building it"
    if ! "$SOURCEROOT/addons/docker-build/build-devcontainer.sh"; then
      echo "Failed to build devcontainer"
      exit 1
    fi
  fi
  mkdir -p "$WHRUNKIT_TARGETDIR/whbuild"
  mkdir -p "$WHRUNKIT_DATADIR/_settings/shared-dev-buildroot"
  echo "$WHRUNKIT_DATADIR/_settings/shared-dev-buildroot" > "$WHRUNKIT_TARGETDIR/whbuildroot"
  echo "wh shell" > "$WHRUNKIT_TARGETDIR/cmdline"
  echo "/tmp" > "$WHRUNKIT_TARGETDIR/tmpfs"
  echo "--publish=${BASEPORT}:13679" > "$WHRUNKIT_TARGETDIR/container-options"
  echo "WEBHARE_RESCUEPORT_BINDIP=0.0.0.0" > "$WHRUNKIT_TARGETDIR/environment"
fi

if [ -n "$IMAGE" ]; then # For create-server, not setting an image has no direct effect (unlike upgrade which reapplies the current tag)
  configure_runkit_podman
  set_webhare_image "$IMAGE"
fi

#TODO allow creating the PRIMARY installation
echo "$BASEPORT" > "$WHRUNKIT_TARGETDIR/baseport"
[ -n "$SOURCEROOT" ] && echo "$SOURCEROOT" > "$WHRUNKIT_TARGETDIR/sourceroot"

loadtargetsettings # reload to ensure we have loaded baseport/data settings

if [ "$RUNMAKE" == "1" ]; then
  echo "Running 'make install' in the WebHare source tree..."
  # shellcheck source=../atserver/run-webhare.sh
  ( source "${BASH_SOURCE%/*}/../atserver/run-webhare.sh" -- wh make install )
fi

if [ -z "$QUIET" ]; then
  echo "Server created. To start: 'runkit @$WHRUNKIT_TARGETSERVER run-webhare' and access the server on http://127.0.0.1:$(($WEBHARE_BASEPORT))"
  echo "Don't forget to run 'runkit-reload' to activate the 'wh-$WHRUNKIT_TARGETSERVER' command"
fi
