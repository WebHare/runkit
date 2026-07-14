#!/bin/bash

mkdir -p "$WHRUNKIT_DATADIR/_log"

# cleanup loadreports more than 4 weeks old
find "$WHRUNKIT_DATADIR/_log/loadreports" -mindepth 1 -type d -mmin +40320 -exec rm -rf {} \;

# log last daily-maintenance run
date > "$WHRUNKIT_DATADIR/_log/.last-daily-maintenance"

# Prune old containers
if hash podman >/dev/null 2>/dev/null ; then
  # Cleans all shutdown containers created more than 48 hours ago.
  podman container prune --force --filter until="48h"

  # List currently prepared images
  REFERREDIMAGES=()
  for IMAGEFILE in "$WHRUNKIT_DATADIR"/*/container.image ; do
    REFERREDIMAGES+=("$(cat "$IMAGEFILE" 2>/dev/null || true)")
  done

  # limiting created images older than 7 days to prevent too early removal of build artifacts. note that this looks at image creation time, not download time so it's not protecting pulled images
  # "Id" gives us the full image ID, "ID" gives us a truncated one
  # dangling=true are truly unconnected untagged aimges
  # container=false are images currently unused by a container
  for IMAGE in $(podman images --filter until="168h" --filter dangling=true --format "{{.Id}}") $(podman images --filter until="168h" --filter container=false --format "{{.Id}}"); do
    PRUNE_IMAGE=1
    # filter out images referenced by container.image files but not yet started
    for IMG in "${REFERREDIMAGES[@]}"; do
      if [[ "$IMG" == "$IMAGE" ]]; then
        PRUNE_IMAGE=0
        break
      fi
    done

    if [[ $PRUNE_IMAGE -eq 1 ]]; then
      podman image rm "$IMAGE"
    fi
  done

  podman volume prune --force
fi
