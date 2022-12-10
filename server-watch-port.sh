#!/bin/bash
port=9012
while :; do
    if ! curl -s localhost:$port > /dev/null; then                             
        echo "$(date +'%Y-%m-%d %H:%M') : Killing the process related to port:$port"
        sudo fuser -k $port/tcp
    fi
    sleep 5
done
