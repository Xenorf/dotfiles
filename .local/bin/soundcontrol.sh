#!/bin/sh
ACTIVE_SINK=$(pactl list sinks | grep -i 'active port' | grep -i 'analog-output-headphones' | awk '{ print $3 }')

icon=$XDG_CONFIG_HOME/resources/icons/sound.png

if [ "$ACTIVE_SINK" = "analog-output-headphones" ]; then
	echo "[+] Switching to line out output port"
	pactl set-sink-port @DEFAULT_SINK@ analog-output-lineout
	notify-send -i $icon "Sound is now outputed on speakers"
else
	echo "[+] Switching to headphones"
	pactl set-sink-port @DEFAULT_SINK@ analog-output-headphones
	notify-send -i $icon "Sound is now outputed in headphones"
fi
