#!/bin/sh
#
if [ "$#" -ne 1 ] || [ "$1" != "install" ] && [ "$1" != "uninstall" ]; then
	echo "Usage: $0 [install | uninstall]"
	exit 1
fi

echo "Current state of plugged disks: "
lsblk
echo "Which disk is Arch Linux installed on?"
read answer
device="/dev/$answer"

current_entry=$(efibootmgr | grep -i "Arch Linux" | awk '{print $1}' | sed 's/[^0-9]*//g')
current_kernel_params=$(efibootmgr -u | grep -o 'rd.luks.name.*')

operation=$1

if [ "$operation" = "install" ]; then
	echo "[+] Installing NVIDIA drivers"
	pacman -S nvidia
	echo "options nvidia-drm modeset=1" >/etc/modprobe.d/nvidia.conf
	sed -i '/^MODULES=(/ s/ nouveau//g' /etc/mkinitcpio.conf
	sed -i '/^HOOKS=(/ s/ kms//g' /etc/mkinitcpio.conf
	sed -i '/^MODULES=(/ s/)$/\ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
	new_kernel_params="${current_kernel_params} nvidia_drm.modeset=1"
elif [ "$operation" = "uninstall" ]; then
	echo "[+] Uninstalling NVIDIA drivers"
	pacman -Rns nvidia-dkms
	pacman -Rns nvidia-open-dkms
	pacman -Rns nvidia
	pacman -Rns nvidia-utils
	echo "[+] Removing configuration files"
	rm /etc/modprobe.d/nvidia.conf
	rm /etc/pacman.d/hooks/nvidia.hook
	echo "[+] Modifying mkinitcpio"
	sed -i '/^HOOKS=(/ s/modconf/modconf kms/g' /etc/mkinitcpio.conf
	sed -i '/^MODULES=(/ s/nvidia nvidia_modeset nvidia_uvm nvidia_drm//g' /etc/mkinitcpio.conf
	new_kernel_params=$(echo "$current_kernel_params" | sed 's/nvidia_drm\.modeset=1//')
	mkinitcpio -P
fi

if [ -n "$current_entry" ]; then
	echo "[+] Modifying existing bootloader entry"
	efibootmgr -b "$current_entry" -B
	efibootmgr -d $device -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "$new_kernel_params"
else
	echo '[-] There is no boot entry matching the label "Arch Linux"'
fi
