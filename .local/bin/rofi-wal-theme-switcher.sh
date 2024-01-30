#!/bin/sh
#find ~/.config/resources/wallpapers -type f -printf "preload = \$XDG_CONFIG_HOME/resources/wallpapers/%f\n"

WALLPAPERDIR="$XDG_CONFIG_HOME/resources/wallpapers"

get_themes() {
	ls "$WALLPAPERDIR"
}
if [ "$1" = "--random" ]; then
	selected_theme=$(basename $(find "$XDG_CONFIG_HOME/resources/wallpapers" -type f | shuf -n 1))
else
	selected_theme=$(get_themes | rofi -dmenu -p "Select Wallpaper Theme")
fi

if [ -n "$selected_theme" ]; then
	echo "DP-1,$WALLPAPERDIR/$selected_theme"
	hyprctl hyprpaper wallpaper "DP-1,$WALLPAPERDIR/$selected_theme"
	wal -i "$WALLPAPERDIR/$selected_theme" --saturate 0.6 >/dev/null
	killall -SIGUSR2 waybar
	# Make the change persitent
	sed -i "s/^\(wallpaper =[^,]*\),.*/\1,\$XDG_CONFIG_HOME\/resources\/wallpapers\/$selected_theme/" $XDG_CONFIG_HOME/hypr/hyprpaper.conf
else
	exit 0
fi
