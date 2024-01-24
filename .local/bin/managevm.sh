#!/bin/sh

vm_status=$(virsh --connect qemu:///system domstate win11 | head -n 1)
echo "Current VM status: $vm_status"
icon=$XDG_CONFIG_HOME/resources/icons/windows.png

if [ "$vm_status" = "shut off" ]; then
	virsh --connect qemu:///system start win11
	notify-send -i $icon "Windows 11 VM is starting"
	while
		virsh --connect qemu:///system qemu-agent-command win11 '{"execute":"guest-info"}' >/dev/null 2>&1
		[ $? -eq 1 ]
	do
		sleep 5
	done
	notify-send -i $icon "Windows 11 VM is now running"
elif [ "$vm_status" = "running" ]; then
	virsh --connect qemu:///system shutdown win11
	notify-send -i $icon "Windows 11 VM is shutting down"
	while [ "$vm_status" = "running" ]; do
		sleep 1
		vm_status=$(virsh --connect qemu:///system domstate win11 | head -n 1)
	done
	notify-send -i $icon "Windows 11 VM is now shut down"
fi
