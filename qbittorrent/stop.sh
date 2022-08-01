#! /bin/bash

# If qbittorrent-pre-stop.sh exists, run it
if [[ -x /scripts/qbittorrent-pre-stop.sh ]]
then
    echo "Executing /scripts/qbittorrent-pre-stop.sh"
    /scripts/qbittorrent-pre-stop.sh "$@"
    echo "/scripts/qbittorrent-pre-stop.sh returned $?"
fi

echo "Sending kill signal to qbittorrent-nox"
PID=$(pidof qbittorrent-nox)
kill "$PID"

# Give qbittorrent-nox some time to shut down
QBT_TIMEOUT_SEC=${QBT_TIMEOUT_SEC:-5}
for i in $(seq "$QBT_TIMEOUT_SEC")
do
    sleep 1
    [[ -z "$(pidof qbittorrent-nox)" ]] && break
    [[ $i == 1 ]] && echo "Waiting ${QBT_TIMEOUT_SEC}s for qbittorrent-nox to die"
done

# Check whether qbittorrent-nox is still running
if [[ -z "$(pidof qbittorrent-nox)" ]]
then
    echo "Successfuly closed qbittorrent-nox"
else
    echo "Sending kill signal (SIGKILL) to qbittorrent-nox"
    kill -9 "$PID"
fi

# If qbittorrent-post-stop.sh exists, run it
if [[ -x /scripts/qbittorrent-post-stop.sh ]]
then
    echo "Executing /scripts/qbittorrent-post-stop.sh"
    /scripts/qbittorrent-post-stop.sh "$@"
    echo "/scripts/qbittorrent-post-stop.sh returned $?"
fi
