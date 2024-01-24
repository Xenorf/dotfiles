#!/bin/sh

# Take a screenshot using grim command and save it with a temporary file name
tmp_file=$(mktemp /tmp/screenshot_XXXXXX.png)
grim -t png -g "$(slurp -d)" $tmp_file
wl-copy <$tmp_file

while true; do
	# Use Rofi prompt to ask for a file name
	file_name=$(echo -n "" | rofi -dmenu -p "Enter file name")

	# Check if a file name was entered
	if [ -z "$file_name" ]; then
		notify-send "No file name entered. Aborting."
		exit 1
	fi

	if [ -f $HOME/documents/screenshots/$file_name.png ]; then
		choice=$(echo -e "rename\nreplace\nkeep & ignore" | rofi -dmenu -p "File with the same name exists!")

		case "$choice" in
		"rename")
			continue
			;;
		"replace")
			mv "$tmp_file" "$HOME/documents/screenshots/$file_name.png"
			notify-send "Screenshot replaced the existing picture."
			break
			;;
		"keep & ignore")
			rm $tmp_file
			notify-send "Screenshot discarded. Existing picture kept."
			break
			;;
		*)
			notify-send "Invalid choice or no action taken. Aborting."
			rm $tmp_file
			exit 1
			;;
		esac
	else
		mv "$tmp_file" "$HOME/documents/screenshots/$file_name.png"
		notify-send "Screenshot saved as $file_name.png"
		break
	fi
done
