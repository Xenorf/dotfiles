#!/bin/sh
#set -e
echo "Current state of plugged disks: "
lsblk
echo "Which disk would you like to install Arch Linux on?"
read answer
device="/dev/$answer"
esp_partition="${device}1"
main_partition="${device}2"

# Partitioning
if [ -e "$device" ]; then
	echo "Running dd on $device"
	dd if=/dev/zero of=$device bs=446 count=1
	dd if=/dev/zero of=$esp_partition bs=512 count=1
	sgdisk --zap-all $device
	sgdisk --clear --new=1:0:+512M --typecode=1:ef00 --new=2:0:0 --typecode=2:8309 $device
else
	echo "$device is not a valid disk for installation, aborting..."
	exit 1
fi

cryptsetup_name="cryptlvm"
lvm_vg_name="archvg"
echo "[+] Encrypting the disk"
cryptsetup -y -v luksFormat $main_partition
cryptsetup open $main_partition $cryptsetup_name

echo "[+] Creating physical and logical volumes"
pvcreate /dev/mapper/$cryptsetup_name
vgcreate $lvm_vg_name /dev/mapper/$cryptsetup_name

lvcreate -L 16G $lvm_vg_name -n swap
lvcreate -l 100%FREE $lvm_vg_name -n root
lvreduce -L -256M $lvm_vg_name/root

# Formatting
echo "[+] Formatting the partitions"
root_partition=/dev/mapper/$lvm_vg_name-root
swap_partition=/dev/mapper/$lvm_vg_name-swap

mkfs.fat -F32 $esp_partition
mkfs.ext4 $root_partition
mkswap $swap_partition

# Mounting
echo "[+] Mounting the partitions"
mount $root_partition /mnt
mount --mkdir $esp_partition /mnt/boot
swapon $swap_partition

# Installing packages
echo "[+] Installing default packages"
package_list="base linux linux-firmware base-devel neovim efibootmgr lvm2 mkinitcpio networkmanager git sbctl"
vendor=$(lscpu | grep -i '^vendor' | awk '{print $3}')
if [ "$vendor" = "GenuineIntel" ]; then
	echo "Processor is Intel"
	package_list="$package_list intel-ucode"
elif [ "$vendor" = "AuthenticAMD" ]; then
	echo "Processor is AMD"
	package_list="$package_list  amd-ucode"
else
	echo "Processor vendor unknown or not recognized"
fi
pacstrap /mnt $package_list

# Creating bootloader entry
echo "[+] Creating bootloader entry"
root_uuid=$(blkid -s UUID -o value $root_partition)
swap_uuid=$(blkid -s UUID -o value $swap_partition)
device_uuid=$(blkid -s UUID -o value $main_partition)
echo "device: $device | device_uuid: $device_uuid | cryptsetup_name: $cryptsetup_name | swap_uuid: $swap_uuid | root_uuid: $root_uuid"
sleep 5
efibootmgr -d $device -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "rd.luks.name=$device_uuid=$cryptsetup_name resume=UUID=$swap_uuid root=UUID=$root_uuid initrd=\initramfs-linux.img iommu=pt rw"

echo "What hostname do you want to give?"
read hostname
echo "What password do you want to set for the root user?"
read root_password

genfstab -U /mnt >>/mnt/etc/fstab

echo "[+] Chrooting"

arch-chroot /mnt << EOF
echo "[+] Setting important parameters"
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 >/etc/locale.conf
echo $hostname >/etc/hostname

echo "[+] Modifying the initramfs"
sed -i 's/^HOOKS=.*/HOOKS=(systemd autodetect modconf kms keyboard block sd-encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
sed -i 's/^PRESETS=.*/PRESETS=("default")/' /etc/mkinitcpio.d/linux.preset
mkinitcpio -P

echo "[+] Enabling internet"
systemctl enable NetworkManager

echo "[+] Modifying the root password"
passwd
$root_password
$root_password

EOF

# Cleaning
echo "Is everything OK? [y/N]"
read answer
case "$answer" in
[Yy])
	echo "[+] Cleaning"
	umount -R /mnt
	swapoff -a
	cryptsetup close $lvm_vg_name-root
	cryptsetup close $lvm_vg_name-swap
	cryptsetup close $cryptsetup_name
	;;
*)
	echo "[-] Not cleaning up, you will have to do it yourself"
	;;
esac
