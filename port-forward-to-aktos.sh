#!/bin/bash
while :; do
    ssh -o ServerAliveInterval=2 -o ServerAliveCountMax=2 -o ExitOnForwardFailure=yes -o AddressFamily=inet -N -KL 4012:localhost:4032 aktos1
    echo Retrying
    sleep 5
done
