#!/bin/sh
if [ -z "$1" ] || [ "$1" != "plug" ] && [ "$1" != "unplug" ]; then
	echo "Usage: $0 <plug|unplug>"
	exit 1
fi
icon="$HOME/.config/resources/icons/usbkey.png"

usb_action="$1"

case "$usb_action" in
"plug")
	dunstify "USB key plugged in"
	DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus dunstify -I $icon "USB key plugged in"
	;;
"unplug")
	dunstify "USB key unplugged"
	DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus dunstify -I $icon "USB key unplugged"
	;;
esac
