#!/bin/bash

function onexit()
{
  rv=$? #Make sure we don't destroy the exit code
  [ -n "$WEBHARE_RUNKIT_KEYFILE" ] && rm "$WEBHARE_RUNKIT_KEYFILE"
  exit $rv
}

function die()
{
  echo "$@" 1>&2
  exit 1
}

function ensurecommands()
{
  if ! hash "$@" >/dev/null 2>&1 ; then
    "$WHRUNKIT_ROOT/bin/setup.sh"
  fi
}

function iscontainerup()
{
  [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null )" == true ] && return 0 || return 1
}

function killcontainer()
{
  if docker inspect "$1" > /dev/null 2>&1 ; then
    (docker stop "$1" 2>/dev/null && sleep 1) || true
    docker kill "$1" 2>/dev/null || true
    docker rm -f "$1"
  fi
}

function configuredocker()
{
  if ! docker network inspect webhare-runkit > /dev/null 2>&1 ; then
    echo -n "Creating webhare-runkit network: "
    docker network create webhare-runkit --subnet=10.15.19.0/24
  fi
}

function createCacheDirTagFile
{
  cat << HERE > "$1/CACHEDIR.TAG"
Signature: 8a477f597d28d172789f06886806bc55
# This file is a cache directory tag created by webhare-runkit.
# For information about cache directory tags, see:
# https://bford.info/cachedir/
HERE
}

function applyborgsettings()
{
  local SETTINGSNAME
  SETTINGSNAME="$1"

  ensurecommands borg

  #TODO how risky is accept-new (in practice) ?
  export BORG_PRIVATEKEY=
  export BORG_REPO=
  export BORG_PASSPHRASE=

  WHRUNKIT_TARGETSERVER="$1"

  if [ -f "$WHRUNKIT_DATADIR/_settings/getborgsettings.sh" ]; then
    #Note: getborgsettings is specifically allowed (encouraged?) to update WHRUNKIT_TARGETSERVER
    source "$WHRUNKIT_DATADIR/_settings/getborgsettings.sh"
  fi

  validate_servername "$WHRUNKIT_TARGETSERVER"
  loadtargetsettings

  if [ -z "$BORG_REPO" ]; then
    BORGSETTINGSFILE="$WHRUNKIT_TARGETDIR/borgsettings"
    if [ ! -f "$BORGSETTINGSFILE" ]; then
      echo Cannot locate expected settings file at "$BORGSETTINGSFILE"
      [ -n "$WHRUNKIT_ONMISSINGSETTINGS" ] && echo "$WHRUNKIT_ONMISSINGSETTINGS"
      exit 1
    fi
    source "$BORGSETTINGSFILE"
  fi

  [ -n "$BORG_REPO" ] || die "Missing BORG_REPO"
  [ -n "$BORG_PRIVATEKEY" ] || die "Missing BORG_PRIVATEKEY"
  [ -n "$BORG_PASSPHRASE" ] || die "Missing BORG_PASSPHRASE"

  # TODO is there a way to not persist the privatesshkey ? and avoiding ssh-agent which comes with its own persisting process problems ?
  SAVEUMASK=$(umask)
  WEBHARE_RUNKIT_KEYFILE="$(mktemp)"
  umask 077
  echo "$BORG_PRIVATEKEY" > "$WEBHARE_RUNKIT_KEYFILE"
  umask "$SAVEUMASK"

  export BORG_RSH="ssh -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes -i $WEBHARE_RUNKIT_KEYFILE"
  mkdir -p "$WHRUNKIT_TARGETDIR"
}

function settargetdir
{
  if [ -z "$WHRUNKIT_TARGETSERVER" ]; then
    echo "WHRUNKIT_TARGETSERVER must be set!"
    exit 1
  fi

  if [ "$WHRUNKIT_TARGETSERVER" == "default" ]; then
    for SERVER in $( cd "$WHRUNKIT_DATADIR" ; echo * | sort); do
      BASEPORT="$(cat "$WHRUNKIT_DATADIR/$SERVER/baseport" 2>/dev/null)"
      if [ "$BASEPORT" == "13679" ]; then
        WHRUNKIT_TARGETSERVER="$SERVER"
        break
      fi
    done
    if [ "$WHRUNKIT_TARGETSERVER" == "default" ]; then
      echo "No server is listening on port 13679 - cannot find the default"
      echo "See also: https://gitlab.com/webhare/runkit#managing-webhare-installations"
      exit 1
    fi
  fi

  WHRUNKIT_TARGETDIR="$WHRUNKIT_DATADIR/$WHRUNKIT_TARGETSERVER"
}

function trysetsourcerootfromglobal
{
  if [ -f "$WHRUNKIT_DATADIR/_settings/sourceroot" ]; then
    WEBHARE_CHECKEDOUT_TO="$(cat "$WHRUNKIT_DATADIR/_settings/sourceroot")"
    WEBHARE_DIR="${WEBHARE_CHECKEDOUT_TO%/}/whtree"
  fi
  export WEBHARE_CHECKEDOUT_TO WEBHARE_DIR
}

function loadtargetsettings
{
  settargetdir

  export WEBHARE_INITIALDB=postgresql #will soon be obsolete, if not already
  WEBHARE_ISRESTORED=""
  WEBHARE_BASEPORT="$(cat "$WHRUNKIT_TARGETDIR/baseport" 2>/dev/null || true)"
  WEBHARE_DATAROOT="$(cat "$WHRUNKIT_TARGETDIR/dataroot" 2>/dev/null || true)"
  if [ -z "$WEBHARE_DATAROOT" ]; then
    WEBHARE_DATAROOT="$WHRUNKIT_TARGETDIR/whdata"
    mkdir -p "$WEBHARE_DATAROOT"
  fi

  if [ -f "$WHRUNKIT_TARGETDIR/sourceroot" ]; then
    WEBHARE_CHECKEDOUT_TO="$(cat "$WHRUNKIT_TARGETDIR/sourceroot")"
    WEBHARE_DIR="${WEBHARE_CHECKEDOUT_TO%/}/whtree" # strip any slash
  else
    trysetsourcerootfromglobal
  fi

  if [ -f "$WEBHARE_DATAROOT/webhare.restoremode" ]; then #FIXME WebHare should implement this itself, see https://gitlab.webhare.com/webharebv/codekloppers/-/issues/583 - and retain this a while for compatibility!
    WEBHARE_ISRESTORED="$(cat "$WEBHARE_DATAROOT/webhare.restoremode")"
  fi

  export WEBHARE_CHECKEDOUT_TO WEBHARE_BASEPORT WEBHARE_DATAROOT WEBHARE_ISRESTORED WEBHARE_DIR
}

function download_backup()
{
  local RESTOREARCHIVE RESTORETO
  RESTOREARCHIVE="$1"
  RESTORETO="$2"

  if [ -z "$RESTOREARCHIVE" ]; then
    RESTOREARCHIVE="$(borg list --short --last 1)"
    [ -z "$RESTOREARCHIVE" ] && echo "No archive found!" && exit 1
  else
    # borg will print error messages to stderr (like "Archive ... does not exist")
    borg info "::$RESTOREARCHIVE" > /dev/null || exit 1
  fi

  echo "$RESTOREARCHIVE" > "$WHRUNKIT_TARGETDIR/restore.archive" #FIXME also apply to webhare.restore file
  date "+%Y-%m-%d" > "$WHRUNKIT_TARGETDIR/restore.date"
  echo "$BORG_REPO" > "$WHRUNKIT_TARGETDIR/restore.borgrepo"

  # remove any existing restore directory
  echo "Downloading archive $RESTOREARCHIVE to $RESTORETO"

  [ -d "$RESTORETO" ] && rm -rf "$RESTORETO"
  mkdir -p "$RESTORETO"
  cd "$RESTORETO"

  # Exclude backup data from backups
  createCacheDirTagFile "$RESTORETO"
  borg extract "${BORGOPTIONS[@]}" "::$RESTOREARCHIVE" $BORGPATHS
  return 0
}

function validate_servername()
{
  # NOTE: what more characters to allow? at least not '.' or '@' to prevent future ambiguity with metadata or remote server names
  if ! [[ $1 =~ ^[a-z][-a-z0-9]*$ ]]; then
    echo "Invalid server name '$1'" 1>&2
    exit 1
  fi
  if [ "$1" == "default" ]; then
    echo "You may not name a server 'default', it's an alias for the server hosted on port 13679"
    exit 1
  fi
}

function ensure_server_baseport()
{
  [ -n "$WHRUNKIT_TARGETDIR" ] || die WHRUNKIT_TARGETDIR must be set before invoking ensure_server_baseport
  [ -f "$WHRUNKIT_TARGETDIR/baseport" ] || echo "$(( RANDOM / 10 * 10 + 20000 ))" > "$WHRUNKIT_TARGETDIR/baseport"
}

function resolve_whrunkit_command()
{
  [ -z "$WEBHARE_DIR" ] && trysetsourcerootfromglobal

  if [ -z "$WEBHARE_DIR" ]; then
    # TODO Should we go around *ensuring* this is set everywhere? Or is this a very acceptible convention?
    #      Or we could just request you set a config option in the datadir point to the SOURCE checkout as that's what runkit needs/manages
    if [ -x "$HOME/projects/webhare/whtree/bin/wh" ]; then
      echo "runkit had to fall back to hardcoded $HOME/projects/webhare/whtree path" >&2
      echo "Please create a file with the full path to your WebHare installation in $WHRUNKIT_DATADIR/_settings/sourceroot" >&2
      echo "\$ echo $HOME/projects/webhare > $WHRUNKIT_DATADIR/_settings/sourceroot" >&2
      sleep 2
      WEBHARE_DIR="$HOME/projects/webhare/whtree"
    fi
  fi

  [ -n "$WEBHARE_DIR" ] && WHRUNKIT_WHCOMMAND="$WEBHARE_DIR/bin/wh"

  export WHRUNKIT_WHCOMMAND
}

function ensure_whrunkit_command()
{
  resolve_whrunkit_command
  [ -n "$WHRUNKIT_WHCOMMAND" ] || die "Don't know where to find your bin/wh"
  [ -x "$WHRUNKIT_WHCOMMAND" ] || die "Don't know where to find your bin/wh, tried '$WHRUNKIT_WHCOMMAND'"
}

function load_forgeroot()
{
  WHRUNKIT_FORGEROOT="$(cat "$WHRUNKIT_DATADIR"/_settings/forgeroot 2>/dev/null || true)"
  [ -n "$WHRUNKIT_FORGEROOT" ] || WHRUNKIT_FORGEROOT="https://gitlab.com/webhare/"
}

# Initialize COMP_WORDS, COMP_CWORD and COMPREPLY. Split on whitespace only, ignoring COMP_WORDBREAKS
autocomplete_init_compwords()
{
  # Parse COMP_LINE, split on whitespace only. Append a char to make sure trailing whitespace isn't lost
  if [ -n "$COMP_POINT" ]; then
    read -r -a COMP_WORDS <<< "${COMP_LINE:0:$COMP_POINT}z"
  else
    read -r -a COMP_WORDS <<< "${COMP_LINE}z"
  fi
  # Find last word and remove the added char from it
  COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1))
  COMP_WORDS[COMP_CWORD]=${COMP_WORDS[$COMP_CWORD]:0:${#COMP_WORDS[$COMP_CWORD]}-1}
  # Make sure COMPREPLY is initialized
  COMPREPLY=()
}

# Print all matches from COMPREPLY, but only those that don't change stuff left to the cursor
autocomplete_print_compreply()
{
  local LASTWORD_PARTS LASTWORD_LASTPART STRIP_CHARS PREFIX
  # Parse the last word using the COMP_WORDBREAKS, append a char to detect stuff ending on a word break
  IFS="\$:\"'=" read -r -a LASTWORD_PARTS <<< "${COMP_WORDS[$COMP_CWORD]}z"
  # And remove that added character again
  LASTWORD_LASTPART=${LASTWORD_PARTS[${#LASTWORD_PARTS[@]}-1]}

  #echo "COMP_WORDBREAKS: $COMP_WORDBREAKS" 1>&2
  #echo "COMP_WORDS[$COMP_CWORD]: ${COMP_WORDS[$COMP_CWORD]}" 1>&2
  #echo "LASTWORD_LASTPART: $LASTWORD_LASTPART" 1>&2


  # calc how many characters from the last word won't be replaced by the shell
  STRIP_CHARS=$((${#COMP_WORDS[$COMP_CWORD]} - ${#LASTWORD_LASTPART} + 1))
  # Make sure we only let suggestions through that append (not those that change stuff left to the cursor)
  TESTLEN=${#COMP_WORDS[$COMP_CWORD]}
  PREFIX="${COMP_WORDS[$COMP_CWORD]:0:TESTLEN}"
  for i in "${COMPREPLY[@]}"; do
    if [ "${i:0:$TESTLEN}" == "$PREFIX" ]; then
      echo "${i:$STRIP_CHARS}"
      #echo "completion: ${i:$STRIP_CHARS}" 1>&2
    fi
  done
}


WHRUNKIT_ROOT="$(cd "${BASH_SOURCE%/*}/.." ; pwd )"
if [ -z "$WHRUNKIT_ROOT" ]; then
   echo "Unable to find our root directory" 1>&2
   exit 1
fi

if [ -z "$WHRUNKIT_DATADIR" ]; then
  if [ "$EUID" == "0" ]; then
    WHRUNKIT_DATADIR="/opt/whrunkit"
  else
    WHRUNKIT_DATADIR="$HOME/whrunkit"
  fi
fi

export WHRUNKIT_DATADIR WHRUNKIT_ROOT
mkdir -p "$WHRUNKIT_DATADIR"
WEBHARE_RUNKIT_KEYFILE=""
trap onexit EXIT #Cleanup WEBHARE_RUNKIT_KEYFILE if it exists
