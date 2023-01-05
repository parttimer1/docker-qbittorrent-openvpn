#!/bin/bash

# this script is called by tunnelUp.sh and provides tunnel parameters


# Source our persisted env variables from container startup
. /etc/qbittorrent/environment-variables.sh

# This script will be called with OpenVPN environment variables
# See https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/#scripting-and-environmental-variables
echo "qBittorrent Up script executed with device=$dev ifconfig_local=$ifconfig_local"
if [[ "$ifconfig_local" = "" ]]; then
  echo "ERROR, unable to obtain tunnel address"
  echo "killing $PPID"
  kill -9 $PPID
  exit 1
fi

# Re-create `--up` command arguments to maintain compatibility with old user scripts
USER_SCRIPT_ARGS=("$dev" "$tun_mtu" "$link_mtu" "$ifconfig_local" "$ifconfig_remote" "$script_context")

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

TUN=${USER_SCRIPT_ARGS[1]}
IFACE_ADDR=${USER_SCRIPT_ARGS[4]}
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


# configure the jackett plugin
if [ -e "$QBT_PROFILE/jackett/config/Jackett/ServerConfig.json" ]
then

    echo "Copying jackett.py to $QBT_PROFILE/qBittorrent/data/nova3/engines/"
    cp /etc/qbittorrent/jackett.py $QBT_PROFILE/qBittorrent/data/nova3/engines/

    # the api key should always resolve on the first try because openvpn takes longer to start. but just in case it doesnt then retry a few times
    for i in {0..5}
    do
        if [ $i -gt 0 ]
        then
            echo "[$i/5] Waiting 10s for jackett api key"
            sleep 10
        fi

        apiKey=$(cat $QBT_PROFILE/jackett/config/Jackett/ServerConfig.json|jq '.["APIKey"]'|sed 's/"//g')
        if [ -n $apiKey ]
        then
            break
        fi
    done
    
    echo "Jackett api key: $apiKey"
     
    cat <<EOF - > $QBT_PROFILE/qBittorrent/data/nova3/engines/jackett.json
    {
        "api_key": "$apiKey",
        "tracker_first": false,
        "url": "$JACKETT_URL"
    }
EOF
fi

echo "STARTING qBitorrent"
qbittorrent-nox -d