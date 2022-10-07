#!/bin/bash

RESETPASSWORD=
while [[ "$1" =~ ^-.* ]]; do
  if [ "$1" == "-v" ]; then
    VERBOSE=-v
    shift
  elif [ "$1" == "--resetpassword" ]; then
    RESETPASSWORD=1
    shift
  else
    echo "Unrecognized option $1"
    exit 1
  fi
done

function clean
{
  return

  if [ -n "$TEMPSERVERSJSONFILE" ]; then
    rm "$TEMPSERVERSJSONFILE"
    TEMPSERVERSJSONFILE=
  fi

  exit 1
}

trap "clean $? $LINENO" EXIT INT TERM ERR


if [ ! -f "$WHRUNKIT_DATADIR/psql-passfile" ]; then
  echo "*:*:*:*:$(mktemp -u XXXXXXXXXXXXXXXXX)" > "$WHRUNKIT_DATADIR/psql-passfile"
fi

resolve_whrunkit_command

if [ ! -S $WEBHARE_DATAROOT/postgresql/.s.PGSQL.5432 ]; then
  echo Could not find the UNIX socket of the database, is @$WHRUNKIT_TARGETSERVER running?
  exit 1
fi

USERNAME=runkit_pgadmin
PASSWORD=$(cat "$WHRUNKIT_DATADIR/psql-passfile" | cut -d: -f5)
SERVERTITLE="@$WHRUNKIT_TARGETSERVER"

IFS=$'\t' PGADMINUSER=($($WHRUNKIT_WHCOMMAND psql -q -t -A -F $'\t' -c "select * from pg_catalog.pg_user where usename='$USERNAME'"))
if [ -z "${PGADMINUSER[0]}" ]; then
  PASSWORD=$(cat $WHRUNKIT_DATADIR/pgadmin-user-password)
  $WHRUNKIT_WHCOMMAND psql -q -c "BEGIN TRANSACTION READ WRITE" -c "CREATE USER $USERNAME WITH PASSWORD '$PASSWORD'" -c "COMMIT"
elif [ -n "$RESETPASSWORD" ]; then
  $WHRUNKIT_WHCOMMAND psql -q -c "BEGIN TRANSACTION READ WRITE" -c "ALTER USER $USERNAME SET PASSWORD '$PASSWORD'" -c "COMMIT"
fi


TEMPSERVERSJSONFILE=$(mktemp /tmp/runkit-pgadmin-servers-$WHRUNKIT_TARGETSERVER.XXXXXXXXXXX)
PYTHON=/Applications/pgAdmin\ 4.app/Contents/Frameworks/Python.framework/Versions/Current/bin/python3
if [ ! -x "$PYTHON" ]; then
  echo Could not find python executable
  exit 1
fi

if ! "$PYTHON" /Applications/pgAdmin\ 4.app/Contents/Resources/web/setup.py --dump-servers "$TEMPSERVERSJSONFILE" --sqlite-path ~/.pgadmin/pgadmin4.db; then
  echo Error exporting current list of servers
  exit 1
fi

IMPORTED=
if ! jq -e ".Servers | to_entries[]  | select( .value.Name == \"$SERVERTITLE\")" "$TEMPSERVERSJSONFILE" > /dev/null; then

  cat > $TEMPSERVERSJSONFILE << HERE
{
    "Servers": {
        "1": {
            "Name": "$SERVERTITLE",
            "Group": "Runkit",
            "Host": "$WEBHARE_DATAROOT/postgresql",
            "Port": 5432,
            "MaintenanceDB": "postgres",
            "Username": "$USERNAME",
            "Role": "$USERNAME",
            "SSLMode": "prefer",
            "SSLCompression": 0,
            "Timeout": 10,
            "UseSSHTunnel": 0,
            "TunnelPort": "22",
            "TunnelAuthentication": 0,
            "PassFile": "$WHRUNKIT_DATADIR/psql-passfile"
        }
    }
}
HERE
  echo "Importing new server-definition into pgAdmin"
  if ! "$PYTHON" /Applications/pgAdmin\ 4.app/Contents/Resources/web/setup.py --load-servers "$TEMPSERVERSJSONFILE" --sqlite-path ~/.pgadmin/pgadmin4.db; then
    echo Error importing new server
    exit 1
  fi
  IMPORTED=1
else
  echo found
fi

if pgrep "pgAdmin 4" > /dev/null; then
  if [ -n "$IMPORTED" ]; then
    echo "Please refresh the 'Runkit' server group (or restart pgAdmin when that group isn't visible yet)"
    sleep 1
  fi
  osascript -e "tell application \"pgAdmin 4\" to activate first window"
else
  echo "Starting pgAdmin 4"
  open /Applications/pgAdmin\ 4.app/
fi
