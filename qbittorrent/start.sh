#!/bin/bash

# this script is called by tunnelUp.sh and provides tunnel parameters


# Source our persisted env variables from container startup
. /etc/qbittorrent/environment-variables.sh

echo "qBittorrent up script executed with $*"

if [[ "$4" = "" ]]; then
  echo "ERROR, unable to obtain tunnel address"
  echo "killing $PPID"
  kill -9 $PPID
  exit 1
fi

if [[ ! -d "$QBT_PROFILE" ]] 
then
    echo "Invalid QBT_PROFILE path"
    exit 1
fi


if [[ -z "$QBT_WEBUI_PORT" ]] 
then
    echo "Invalid QBT_WEBUI_PORT path"
    exit 1
fi

TUN=$1
IFACE_ADDR=$4
CONF_PATH=$QBT_PROFILE/qBittorrent/config
CONF_FILE=$CONF_PATH/qBittorrent.conf

if [ ! -f "$CONF_FILE" ]
then
    mkdir -p $CONF_PATH
    cat /etc/qbittorrent/initial-qBittorrent.conf > $CONF_FILE
fi

sed -i -E 's/^.*\b(Connection\\Interface)\b.*$/\1='"$TUN"'/' "$CONF_FILE"
sed -i -E 's/^.*\b(Connection\\InterfaceAddress)\b.*$/\1='"$IFACE_ADDR"'/' "$CONF_FILE"
sed -i -E 's/^.*\b(Connection\\InterfaceName)\b.*$/\1='"$TUN"'/' "$CONF_FILE"
sed -i -E 's/^.*\b(WebUI\\Port)\b.*$/\1='"$QBT_WEBUI_PORT"'/' "$CONF_FILE"
# use pipe delimter because QBT_DOWNLOAD_DIR contains slashes
sed -i -E 's|^.*\b(Downloads\\SavePath)\b.*$|\1='"$QBT_DOWNLOAD_DIR"'|' "$CONF_FILE"

echo "STARTING qBitorrent"
qbittorrent-nox