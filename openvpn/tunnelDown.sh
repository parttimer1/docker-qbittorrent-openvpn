#!/bin/bash

. /etc/qbittorrent/environment-variables.sh

#tunnel is down, restore resolv.conf to previous version
if ls /etc/resolv.conf-*.sv 1> /dev/null 2>&1; then
    cp /etc/resolv.conf-*.sv /etc/resolv.conf
    echo "resolv.conf was restored"
else
    echo "resolv.conf backup not found, could not restore"
fi

if [[ -z "$TORRENT_CLIENT" ]] 
then
    TORRENT_CLIENT="transmission"
fi

/etc/$TORRENT_CLIENT/start.sh "$@"
[[ -f /opt/privoxy/stop.sh ]] && /opt/privoxy/stop.sh
