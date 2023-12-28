#!/bin/bash

if [ "$UID" -ne 0 ]; then
	echo "You need to run this script as root"
	exit 1
fi

if ! [ "$SUDO_USER" = "" ]; then
	echo "Running as sudo isn't adviced"
fi

set -x

if /usr/local/bin/virt-listgpu "$1"; then
	if [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
		systemctl stop display-manager
		umount /dev/sdb1
		echo 0 > /sys/class/vtconsole/vtcon0/bind
		echo 0 > /sys/class/vtconsole/vtcon1/bind
		echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
		modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia
		virsh nodedev-detach pci_0000_01_00_0
		virsh nodedev-detach pci_0000_01_00_1
		modprobe vfio-pci
	elif [ "$2" = "release" ] && [ "$3" = "end" ]; then
		virsh nodedev-reattach pci_0000_01_00_0
		virsh nodedev-reattach pci_0000_01_00_1
		modprobe -r vfio_pci
		echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind
		modprobe nvidia_drm
		modprobe nvidia_modeset
		modprobe nvidia_uvm
		modprobe nvidia
		echo 1 > /sys/class/vtconsole/vtcon0/bind
		echo 1 > /sys/class/vtconsole/vtcon1/bind
		mount /dev/sdb1 /mnt/data -o umask=0022,gid=1000,uid=1000 &
		systemctl start display-manager
	fi
fi
