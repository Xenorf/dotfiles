#!/bin/bash
set -e

echo "Installing required packages"
pacman -S virt-manager virt-viewer qemu vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf swtpm

echo "Editing /etc/libvirt/libvirtd.conf"
sed -i '/^#unix_sock_group/s/^#//' /etc/libvirt/libvirtd.conf
sed -i '/^#unix_sock_rw_perms/s/^#//' /etc/libvirt/libvirtd.conf
echo 'log_filters="3:qemu 1:libvirt"' >>/etc/libvirt/libvirtd.conf
echo 'log_outputs="2:file:/var/log/libvirt/libvirtd.log"' >>/etc/libvirt/libvirtd.conf

echo "Editing /etc/libvirt/qemu.conf"
sed -i "s/^#user = .*/user = \"$SUDO_USER\"/" /etc/libvirt/qemu.conf
sed -i "s/^#group = .*/group = \"$SUDO_USER\"/" /etc/libvirt/qemu.conf

echo "Adding $SUDO_USER to the kvm and libvirt groups"
usermod -a -G kvm,libvirt $SUDO_USER

echo "Enabling services and autostart"
systemctl enable libvirtd
systemctl start libvirtd
virsh net-autostart default

echo "GPU passthrough setup\n"
echo "Editing mkinitcpio to early load vfio drivers"
sed -i '/^MODULES=/ s/(\(.*\))/\(vfio_pci vfio vfio_iommu_type1 \1\)/' /etc/mkinitcpio.conf
mkinitcpio -P

echo "Scanning IOMMU groups"
shopt -s nullglob

matching_group_found=false
groups=()
for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
	group_number=${g##*/}
	groups+=("$group_number")

	contains_vga_or_3d=false
	for d in $g/devices/*; do
		device_info=$(lspci -nns ${d##*/})
		if [[ $device_info =~ VGA|3D ]]; then
			contains_vga_or_3d=true
			matching_group_found=true
			break
		fi
	done

	if [ $contains_vga_or_3d == true ]; then
		echo "IOMMU Group $group_number:"
		for d in $g/devices/*; do
			echo -e "\t$(lspci -nns ${d##*/})"
		done
	fi
done

if [ $matching_group_found == false ]; then
	echo "No IOMMU group containing a GPU found. Check that IOMMU is enabled."
	exit 1
fi

# Prompt the user to choose an IOMMU group
read -p "Choose an IOMMU group number: " selected_group

# Validate user input
if [[ ! " ${groups[@]} " =~ " $selected_group " ]]; then
	echo "Invalid selection. You will have to manually edit /etc/modprobe.d/vfio.conf"
	exit 1
fi

selected_group_output=$(find /sys/kernel/iommu_groups/$selected_group/devices/* -exec sh -c 'lspci -nns "$(basename "$0")"' {} \;)

echo "Selected IOMMU Group $selected_group:"
vfioline=$(echo -e "$selected_group_output" | grep -oP '\[\K[0-9a-f]+:[0-9a-f]+' | tr '\n' ',' | sed 's/,$/ disable_vga=1/')
vfioline="options vfio-pci ids=${vfioline}"

echo $vfioline
read -p "Does this line looks correct to you? [y/N] " answer
case "$answer" in
[Yy])
	echo "Writing the result to /etc/modprobe.d/vfio.conf"
	echo $vfioline >/etc/modprobe.d/vfio.conf
	;;
*)
	echo "You will have to manually edit /etc/modprobe.d/vfio.conf"
	;;
esac

echo "Installing looking glass tweeks"
# Missing the uncomment of cgroup_device_acl in /etc/libvirt/qemu.conf and adding /dev/kvmfr0 (https://forum.level1techs.com/t/sovlde-cant-open-backing-store-dev-kvmfr0-for-guest-ram-operation-not-permitted/180606/3)
#echo "f /dev/shm/looking-glass 0660 $SUDO_USER kvm -" > /etc/tmpfiles.d/10-looking-glass.conf
echo "SUBSYSTEM==\"kvmfr\", OWNER=\"$SUDO_USER\", GROUP=\"kvm\", MODE=\"0660\"" > /etc/udev/rules.d/99-kvmfr.rules
echo "kvmfr" > /etc/modules-load.d/kvmfr.conf
echo "options kvmfr static_size_mb=64" > /etc/modprobe.d/kvmfr.conf

echo "Don't forget to reboot your system"
# Add iommu=pt to bootloader
