#!/bin/bash
LOGDIR="$WHRUNKIT_DATADIR/_log/loadreports/$(date +%Y-%m-%d)"
mkdir -p "$LOGDIR"
LOGFILE=$LOGDIR/$(date +%H.%M.%S)

( date ;
  echo ;
  w ;
  echo ;
  free ;
  echo ;
  iostat -kx 5 2 ;
  echo ;
  /usr/sbin/iotop -bn5 -d1 -o -P
  echo ;
  ps faux ;
  echo ;
  cat /proc/meminfo ) > "$LOGFILE" 2>&1
