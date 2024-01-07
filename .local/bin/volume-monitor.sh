#!/bin/bash

volume_signal=13
while read -r line; do
    echo $line
    /usr/bin/kill -$((34+$volume_signal)) $(/usr/bin/pidof dwmblocks)
done < <(alsactl monitor)