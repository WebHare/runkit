#!/bin/bash

exit_syntax()
{
  echo "Syntax: runkit run-proxy [--sh] [--rescue]"
  exit 1
}


DETACH=""
TORUN=()
DOCKEROPTS=()
RESCUE=0
SYSTEMD=

while true; do
  if [ "$1" == "--help" ]; then
    exit_syntax
  elif [ "$1" == "--sh" ]; then
    TORUN=("/bin/bash")
    DOCKEROPTS+=("-t" "-i")
    shift
  elif [ "$1" == "--systemd" ]; then
    SYSTEMD=1
    shift
  elif [ "$1" == "--rescue" ]; then
    TORUN=("/bin/sleep 604800")
    shift
  elif [[ "$1" =~ ^-.* ]]; then
    echo "Invalid switch '$1'"
    exit 1
  else
    break
  fi
done

[ -n "$1" ] && exit_syntax

mkdir -p "$WHRUNKIT_DATADIR/_proxy" # Ensure our datadir is there

# FIXME use last STABLE
[ -f "$WHRUNKIT_DATADIR/_proxy/container.image" ] || echo docker.io/webhare/proxy:master > "$WHRUNKIT_DATADIR/_proxy/container.image"

CONTAINERSTORAGE="$(cat "$WHRUNKIT_DATADIR/_proxy/dataroot" 2>/dev/null || true)"
if [ -z "$CONTAINERSTORAGE" ]; then # not explicitly set
  if [[ $(uname) == "Darwin" ]]; then
    CONTAINERSTORAGE="runkit-proxy-data" # Use a volume so the container can do its chown things and we can test those. proxy container contents are rarely interesting to access on the Mac host
  else
    CONTAINERSTORAGE="$WHRUNKIT_DATADIR/_proxy/data"
  fi
fi

CONTAINERBASENAME="proxy"
CONTAINERNAME="runkit-$CONTAINERBASENAME"
configure_runkit_podman

mkdir -p "$CONTAINERSTORAGE"
RUNIMAGE="$( cat "$WHRUNKIT_DATADIR/_proxy/container.image" )"

if [ -f "$WHRUNKIT_DATADIR/_settings/letsencryptemail" ]; then
  DOCKEROPTS+=(-e WEBHAREPROXY_LETSENCRYPTEMAIL="$(cat "$WHRUNKIT_DATADIR/_settings/letsencryptemail")")
fi
if [ -f "$WHRUNKIT_DATADIR/_settings/publichostname" ]; then
  DOCKEROPTS+=(-e WEBHAREPROXY_ADMINHOSTNAME="$(cat "$WHRUNKIT_DATADIR/_settings/publichostname")")
fi

# TODO support system docker/podman options eg
# - setting a recognizable hostname for the LB?  (eg  "-h" "lb-fra1-19.docker")
# - seting WEBHAREPROXY_ADMINHOSTNAME=do-fra1-19.hw.webhare.net
# - setting WEBHAREPROXY_LETSENCRYPTEMAIL=webhare-servermgmt+letsencypt@webhare.nl
# - setting DNS: "--dns=192.168.198.128" "--dns=8.8.8.8" "--dns=8.8.4.4"
# /opt/webhare-cloud/libexec/run-container.sh  "lb-fra1-19" "-h" "lb-fra1-19.docker" "-e" "TZ=Europe/Amsterdam" "-e" "NGINXPROXY_LOCALHOSTPORT=5442" "-e" "WEBHAREPROXY_ADMINHOSTNAME=do-fra1-19.hw.webhare.net" "-e" "WEBHAREPROXY_LETSENCRYPTEMAIL=webhare-servermgmt+letsencypt@webhare.nl" "--net" "host" "-v" "/opt/dockerstorage/lb-fra1-19/webhare-proxy-data:/opt/webhare-proxy-data/" "--dns=192.168.198.128" "--dns=8.8.8.8" "--dns=8.8.4.4" "--ulimit" "core=0"

if [ "$(uname)" == "Darwin" ]; then
  DOCKEROPTS+=(--publish 10080:80/tcp --publish 10443:443/tcp)
else
  DOCKEROPTS+=(--network host)

  if [ -z "$SYSTEMD" ] && [ "$(systemctl is-active $CONTAINERNAME)" == "active" ]; then
    echo "You need to 'systemctl stop $CONTAINERNAME' before attemping to start us in the foreground"
    exit 1
  fi
fi

cleanup()
{
  if [ -n "$CONTAINERID" ]; then
    echo "- Stopping container $CONTAINERID ($CONTAINERNAME)"
    podman stop "$CONTAINERID"

    [ -x "$WHRUNKIT_DATADIR/_settings/containerchange.sh" ] && "$WHRUNKIT_DATADIR/_settings/containerchange.sh" stopped "$CONTAINERID" "$CONTAINERNAME"

    CONTAINERID=""
  fi
}

# Wrap into function to prevent updates from affecting running scripts
main()
{
  echo "- Stopping any existing container"
  podman stop "$CONTAINERNAME" 2>/dev/null
  podman rm -f -v "$CONTAINERNAME" 2>/dev/null

  echo "- Creating new container"
  CONTAINERID=$(podman create \
               --rm \
               "${DOCKEROPTS[@]}" -i \
               --volume "$CONTAINERSTORAGE:/opt/webhare-proxy-data:Z" \
               -e TZ=Europe/Amsterdam \
               --name "$CONTAINERNAME" \
               --label runkittype=proxy \
               "--ulimit" "core=0" \
               "${RUNIMAGE:-}" \
               "${TORUN[@]}")

  if [ -z "$CONTAINERID" ]; then
    echo Creation failed
    exit 1
   fi

  echo "$CONTAINERID" > "$WHRUNKIT_DATADIR/_proxy/container.id"

  echo "- Starting it"
  if ! podman start $CONTAINERNAME ; then
    echo Startup failed
    exit 1
   fi

  [ -x "$WHRUNKIT_DATADIR/_settings/containerchange.sh" ] && "$WHRUNKIT_DATADIR/_settings/containerchange.sh" started "$CONTAINERID" "$CONTAINERNAME"

  trap cleanup EXIT INT TERM

  if [ "$(uname)" != "Darwin" ]; then
    PID="$(podman inspect -f '{{.State.Pid}}' $CONTAINERNAME)"
    mkdir -p /runkit-containers/
    rm /runkit-containers/$CONTAINERBASENAME 2> /dev/null
    ln -s /proc/$PID/root /runkit-containers/$CONTAINERBASENAME
  fi

  echo "===== vvv $CONTAINERNAME vvvv ============"
  podman attach $CONTAINERNAME &
  attachpid=$!

  wait $attachpid

  echo "===== ^^^ $CONTAINERNAME stopped ========= (attach returned status code $?)"
}

main "$@"
