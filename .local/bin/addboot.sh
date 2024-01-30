#!/bin/sh
set -e
echo "Current state of plugged disks: "
lsblk
echo "Which disk is Arch Linux installed on?"
read answer
device="/dev/$answer"

esp_partition="${device}1"
main_partition="${device}2"
cryptsetup_name="cryptlvm"
lvm_vg_name="archvg"
root_partition=/dev/mapper/$lvm_vg_name-root
swap_partition=/dev/mapper/$lvm_vg_name-swap
root_uuid=$(blkid -s UUID -o value $root_partition)
swap_uuid=$(blkid -s UUID -o value $swap_partition)
device_uuid=$(blkid -s UUID -o value $main_partition)

echo "[+] Creating bootloader entry"
efibootmgr -d $device -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "rd.luks.name=$device_uuid=$cryptsetup_name resume=UUID=$swap_uuid root=UUID=$root_uuid initrd=\initramfs-linux.img iommu=pt rw"
#efibootmgr -d $device -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "rd.luks.name=$device_uuid=$cryptsetup_name resume=UUID=$swap_uuid root=UUID=$root_uuid initrd=\initramfs-linux.img initcall_blacklist=sysfb_init iommu=pt rw nvidia_drm.modeset=1"
