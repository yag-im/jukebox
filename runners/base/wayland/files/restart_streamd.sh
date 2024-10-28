#!/usr/bin/env bash

if  [[ $EUID = 0 ]]
  then echo "Please do not run as root"
  exit 1
fi

if [ "$#" -lt 2 ]; then
    echo "usage: $0 WS_CONN_ID WS_CONSUMER_ID"
    exit 1
fi

# TODO: pipewire and wireplumber should be restarted properly as well

echo -e "WS_CONN_ID=$1\nWS_CONSUMER_ID=$2" > /home/${USERNAME}/ws.env

# will be restarted in the run_ws.sh loop
pkill -9 streamd
