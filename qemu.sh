#!/bin/bash

if [ "$UID" -ne 0 ]; then
	echo "You need to run this script as root"
	exit 1
fi

if ! [ "$SUDO_USER" = "" ]; then
	echo "Running as sudo isn't adviced"
fi

set -x

HUGEPAGES_SIZE=$(grep Hugepagesize /proc/meminfo | awk {'print $2'})
HUGEPAGES_SIZE=$(($HUGEPAGES_SIZE * 1024))
HUGEPAGES_ALLOCATED=$(sysctl vm.nr_hugepages | awk {'print $3'})
cd $(dirname "$0")
VM_HUGEPAGES_NEED=$(( $(./vm-mem-requirements $1) / HUGEPAGES_SIZE ))

if /usr/local/bin/virt-listgpu "$1"; then
	if [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
		# Shielding
		sync
		echo 3 > /proc/sys/vm/drop_caches
		echo 1 > /proc/sys/vm/compact_memory

		VM_HUGEPAGES_TOTAL=$(($HUGEPAGES_ALLOCATED + $VM_HUGEPAGES_NEED))
		sysctl vm.nr_hugepages=$VM_HUGEPAGES_TOTAL
		
		if [[ $HUGEPAGES_ALLOCATED == "0" ]]; then
			cset set -c "0-7" -s machine.slice
			cset shield --kthread on --cpu "1-3,5-7"
			sysctl vm.stat_interval=120
			sysctl -w kernel.watchdog=0
			echo 77 > /sys/bus/workqueue/devices/writeback/cpumask
			echo never > /sys/kernel/mm/transparent_hugepage/enabled
			echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
			echo 0 > /sys/bus/workqueue/devices/writeback/numa
		fi

		# GPU passthrough
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
		# GPU releasing
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

		# Unshielding
		VM_HUGEPAGES_TOTAL=$(($HUGEPAGES_ALLOCATED - $VM_HUGEPAGES_NEED))
		VM_HUGEPAGES_TOTAL=$(($VM_HUGEPAGES_TOTAL<0?0:$VM_HUGEPAGES_TOTAL))
		sysctl vm.nr_hugepages=$VM_HUGEPAGES_TOTAL

		if [[ $VM_HUGEPAGES_TOTAL == "0" ]]; then
			sysctl vm.stat_interval=1
			sysctl -w kernel.watchdog=1
			echo FF > /sys/bus/workqueue/devices/writeback/cpumask
			cset shield --reset
			echo always > /sys/kernel/mm/transparent_hugepage/enabled
			echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
			echo 1 > /sys/bus/workqueue/devices/writeback/numa
		fi
	fi
fi
