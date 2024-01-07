#!/bin/bash

connection_signal=14
while read -r line; do
    if [[ $line == *"inet "* ]]; then
        echo $line
        /usr/bin/kill -$((34+$connection_signal)) $(/usr/bin/pidof dwmblocks)
    fi
done < <(ip monitor address)