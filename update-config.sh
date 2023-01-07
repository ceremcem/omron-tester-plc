#!/usr/bin/env bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
set -eu 

cd "$_sdir"

cp -v ../config.ls . 
cp -v ../passwords.ls .
cp -v ../passwords.example.ls . 
cp -v ../webapps/main/io-list.ls . 
