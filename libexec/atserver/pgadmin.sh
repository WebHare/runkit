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

PASSFILE="$WHRUNKIT_DATADIR/psql-passfile"
if [ ! -f "$PASSFILE" ]; then
  echo "*:*:*:*:$(mktemp -u XXXXXXXXXXXXXXXXX)" > "$PASSFILE"
fi
chmod 600 "$PASSFILE"

# can runkit read PGHOST/PGUSER from WH ?

# WH5.7
PGHOST="$WEBHARE_DIR/currentinstall/pg"
PGPORT=$((WEBHARE_BASEPORT + 8))

if [ ! -S "$PGHOST/.s.PGSQL.$PGPORT" ]; then
  echo Could not find the UNIX socket of the database, is @$WHRUNKIT_TARGETSERVER running?
  exit 1
fi

USERNAME=runkit_pgadmin
PASSWORD=$(cat "$PASSFILE" | cut -d: -f5)
SERVERTITLE="@$WHRUNKIT_TARGETSERVER"

#note 'usename' is NOT a typo
IFS=$'\t' PGADMINUSER=($($WHRUNKIT_WHCOMMAND psql -q -t -A -F $'\t' -c "select * from pg_catalog.pg_user where usename='$USERNAME'"))
if [ -z "${PGADMINUSER[0]}" ]; then
  $WHRUNKIT_WHCOMMAND psql -q -c "BEGIN TRANSACTION READ WRITE" -c "CREATE USER $USERNAME WITH PASSWORD '$PASSWORD'" -c "COMMIT"
elif [ -n "$RESETPASSWORD" ]; then
  $WHRUNKIT_WHCOMMAND psql -q -c "BEGIN TRANSACTION READ WRITE" -c "ALTER USER $USERNAME SET PASSWORD '$PASSWORD'" -c "COMMIT"
fi

$WHRUNKIT_WHCOMMAND psql -q -c "BEGIN TRANSACTION READ WRITE" -c "ALTER USER $USERNAME WITH SUPERUSER" -c "GRANT ALL PRIVILEGES ON DATABASE webhare TO $USERNAME" -c "COMMIT"


TEMPSERVERSJSONFILE="$(mktemp /tmp/runkit-pgadmin-servers-"$WHRUNKIT_TARGETSERVER".XXXXXXXXXXX)"
PGADMIN_APPDIR="/Applications/pgAdmin 4.app/"
PGADMIN_PYTHON="$PGADMIN_APPDIR/Contents/Frameworks/Python.framework/Versions/Current/bin/python3"
[ -e "$PGADMIN_PYTHON" ] || brew install --cask pgadmin4
[ -x "$PGADMIN_PYTHON" ] || die "Could not find pgAdmin 4 and installation failed. Looking for $PGADMIN_APPDIR"

if ! "$PGADMIN_PYTHON" "$PGADMIN_APPDIR"/Contents/Resources/web/setup.py dump-servers "$TEMPSERVERSJSONFILE" --sqlite-path ~/.pgadmin/pgadmin4.db; then
  echo Error exporting current list of servers
  exit 1
fi

IMPORTED=
if ! jq -e ".Servers | to_entries[]  | select( .value.Name == \"$SERVERTITLE\")" "$TEMPSERVERSJSONFILE" > /dev/null; then
  # adding to a 'Runkit' group doesn't make that group visible. use the Servers group..

  cat > $TEMPSERVERSJSONFILE << HERE
{
    "Servers": {
        "1": {
            "Name": "$SERVERTITLE",
            "Group": "Servers",
            "Host": "$PGHOST",
            "Port": $PGPORT,
            "MaintenanceDB": "webhare",
            "Username": "$USERNAME",
            "Role": "$USERNAME",
            "SSLMode": "prefer",
            "SSLCompression": 0,
            "Timeout": 10,
            "UseSSHTunnel": 0,
            "TunnelPort": "22",
            "TunnelAuthentication": 0,
            "PassFile": "$PASSFILE"
        }
    }
}
HERE


  echo "Importing new server-definition into pgAdmin"
  if ! "$PGADMIN_PYTHON" "$PGADMIN_APPDIR/Contents/Resources/web/setup.py" load-servers "$TEMPSERVERSJSONFILE" --sqlite-path ~/.pgadmin/pgadmin4.db; then
    echo Error importing new server
    exit 1
  fi
  IMPORTED=1
else
  echo found
fi

# Clear environment before starting pgAdmin
unset PGPORT
unset PGHOST
unset PGDATABASE
unset PGUSER

if pgrep "pgAdmin 4" > /dev/null; then
  if [ -n "$IMPORTED" ]; then
    echo "Please refresh the 'Servers' server group (or restart pgAdmin when that group isn't visible yet)"
    sleep 1
  fi
  osascript -e "tell application \"pgAdmin 4\" to activate first window"
else
  echo "Starting pgAdmin 4"
  open "$PGADMIN_APPDIR"
fi
