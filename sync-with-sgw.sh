#!/usr/bin/env bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
set -eu 

script_name="$(basename $0)"

echo_blue () {
    echo -e "\e[1;34m$*\e[0m"
}

echo_yellow () {
    echo -e "\e[1;33m$*\e[0m"
}

echo_green () {
    echo -e "\e[1;32m$*\e[0m"
}


RSYNC="nice -n19 ionice -c3 rsync"

SGW_PORT_ON_SERVER=7104
SGW_USERNAME=aea
SRC_DIR="$_sdir/"
DEST_DIR="./apps/omron-tester-plc/"

timestamp(){
    date +'%Y-%m-%d %H:%M'
}

previous_sync_failed=false
while :; do
    echo_blue "$(timestamp): Synchronizing..."
    if $RSYNC -avzhP --delete \
        --exclude ".git" \
        --exclude "node_modules" \
        --exclude "db_cache" \
        -e "ssh -A -J aktos1 -p ${SGW_PORT_ON_SERVER}" \
        "$SRC_DIR" \
        ${SGW_USERNAME}@localhost:"${DEST_DIR}"; then 
    
        $previous_sync_failed && notify-send -u critical "$script_name Succeeded." "$(timestamp)"
    else
        period=10
        $previous_sync_failed || notify-send -u critical "$script_name Failed." "Retrying in $period seconds."
        sleep $period
        echo_yellow "Retrying..."
        previous_sync_failed=true
        continue
    fi
    $previous_sync_failed || notify-send "Sync done." "$(timestamp): ${DEST_DIR}"

    previous_sync_failed=false

    echo_green "Waiting for directory changes..."
    inotifywait -q -e modify,create,delete -r "$SRC_DIR"
done
