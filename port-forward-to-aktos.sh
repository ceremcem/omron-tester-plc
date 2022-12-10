#!/bin/bash
while :; do
    ssh -o ServerAliveInterval=2 -o ServerAliveCountMax=2 -o ExitOnForwardFailure=yes -o AddressFamily=inet -N -KR 9012:localhost:4011 aktos1
    echo Retrying
    sleep 5
done
