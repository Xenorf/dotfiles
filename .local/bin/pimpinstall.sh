#!/bin/sh

echo "Creating standard user, what name do you want to give?"
read username
sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
useradd -m -G wheel,video,input -s /usr/bin/zsh $username
echo "What password do you want to set for $username?"
passwd $username

echo "[+] Installing important utilities"
pacman -Syu \
	pipewire \
	pipewire-alsa \
	pipewire-pulse \
	wireplumber \
	alsa-utils \
	git \
	linux-headers \
	python \
	python-pip \
	python-pynvim \
	npm \
	unzip \
	wget \
	man-db \
	dash \
	yarn

ln -sfT dash /usr/bin/sh

echo "[+] Installing terminal related utilities"
pacman -S \
	zsh \
	lf \
	tmux \
	zsh-autosuggestions \
	zsh-completions \
	zsh-history-substring-search \
	grc \
	jq

echo "[+] Installing your favorite softwares"
pacman -S \
	keepassxc \
	spotify-launcher \
	chromium \
	discord \
	openvpn \
	qbittorrent \
	vlc \
	barrier \
	calibre \
	gimp \
	bc \
	shotcut \
	obs-studio \
	rclone

echo "[+] Installing packages for the Hyprland ecosystem"
pacman -S \
	hyprland \
	waybar \
	hyprpaper \
	kitty \
	xdg-desktop-portal-hyprland \
	qt6-wayland \
	qt5-wayland \
	wl-clipboard \
	dunst \
	python-pywal \
	ttf-nerd-fonts-symbols-mono \
	noto-fonts-emoji \
	rofi \
	grim \
	slurp

echo "[+] Installing LF preview packages"
pacman -S \
	bat \
	mdcat \
	ffmpegthumbnailer \
	libcdio \
	perl-image-exiftool \
	gnome-epub-thumbnailer \
	poppler

echo "[+] Modifying sound parameters"
cp /usr/share/pipewire/client.conf /etc/pipewire/client.conf
cp /usr/share/pipewire/pipewire-pulse.conf /etc/pipewire/pipewire-pulse.conf
cp -r /usr/share/wireplumber /etc

echo "[+] Installing dotfiles"
sudo -u $username sh -c "cd /home/$username && curl -L https://raw.githubusercontent.com/Xenorf/dotfiles/hyprland/.local/bin/dotfiles-setup.sh | sh"
