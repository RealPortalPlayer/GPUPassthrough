#!/bin/bash
TEMPORARY_ROM_PATH="TEMPORARY_PATH_TEMPORARY_PATH_HACK_TEMPORARY_PATH_WILL_BE_REPLACED"

if [ $# -eq 0 ]; then
	echo "Usage: $0 <vm name>"
	exit 1
fi

FLAGS="-q"

if [ "$DEBUG" == "1" ]; then
	FLAGS="-d"
fi

if /usr/local/bin/virt-listgpu "$1" > /dev/null; then
	echo "The VM already has the GPU passed through"
	exit 1
fi

echo "Removing virtual discs"
virt-xml "$1" "$FLAGS" --remove-device --disk device=cdrom

echo "Removing tablet"
virt-xml "$1" "$FLAGS" --remove-device --input tablet

echo "Removing virtual serial"
virt-xml "$1" "$FLAGS" --remove-device --serial all

echo "Removing Spice audio"
virt-xml "$1" "$FLAGS" --edit --audio type=none

echo "Removing virtual sound"
virt-xml "$1" "$FLAGS" --remove-device --sound all

echo "Removing Spice USB redirectors"
virt-xml "$1" "$FLAGS" --remove-device --redirdev usb

echo "Removing Spice channel"
virt-xml "$1" "$FLAGS" --remove-device --channel all

echo "Removing virtual graphics"
virt-xml "$1" "$FLAGS" --remove-device --graphics all

echo "Removing virtual display"
virt-xml "$1" "$FLAGS" --remove-device --video all

echo "Setting CPU topology"
virt-xml "$1" "$FLAGS" --edit --vcpus sockets=1,dies=1,cores=3,threads=2,maxvcpus=6

echo "Enabling Hugepages"
virt-xml "$1" "$FLAGS" --edit --memorybacking hugepages=on

echo "Pinning CPU cores"

# VCPU CPU CORE
# 0    1   1   - CORE
# 1    5   1   - THREAD
# 2    2   2   - CORE
# 3    6   2   - THREAD
# 4    3   3   - CORE
# 5    7   3   - THREAD
# TODO: Final thread might not be needed?

virt-xml "$1" "$FLAGS" --edit --xml ./cputune/vcpupin\[@vcpu=0\]/@cpuset=1
virt-xml "$1" "$FLAGS" --edit --xml ./cputune/vcpupin\[@vcpu=1\]/@cpuset=5
virt-xml "$1" "$FLAGS" --edit --xml ./cputune/vcpupin\[@vcpu=2\]/@cpuset=2
virt-xml "$1" "$FLAGS" --edit --xml ./cputune/vcpupin\[@vcpu=3\]/@cpuset=6
virt-xml "$1" "$FLAGS" --edit --xml ./cputune/vcpupin\[@vcpu=4\]/@cpuset=3
virt-xml "$1" "$FLAGS" --edit --xml ./cputune/vcpupin\[@vcpu=5\]/@cpuset=7

echo "Setting RAM"
virt-xml "$1" "$FLAGS" --edit --memory 16024

echo "Passing PS/2 keyboard"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/serial\[1\]/@type=dev \
			--xml 	./devices/serial\[1\]/source/@path=/dev/input/by-path/platform-i8042-serio-0-event-kbd

echo "Passing PS/2 mouse"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/serial\[2\]/@type="dev" \
			--xml 	./devices/serial\[2\]/source/@path=/dev/input/by-path/platform-i8042-serio-1-event-mouse \
			--xml	./devices/serial\[2\]/source/target/@port=1
echo "Passing GPU"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[1\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[1\]/source/address/@bus=0x01 \
			--xml ./devices/hostdev\[1\]/rom/@file="$TEMPORARY_ROM_PATH" \
			--xml ./devices/hostdev\[1\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[1\]/@managed=yes

echo "Fixing ROM path"
sed -i "s/$TEMPORARY_ROM_PATH/\/etc\/nvidia.rom/" "/etc/libvirt/qemu/$1.xml"

echo "Reloading modified XML file"
sudo virsh "$FLAGS" define "/etc/libvirt/qemu/$1.xml"

echo "Passing GPU audio"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[2\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[2\]/source/address/@function=0x01 \
			--xml ./devices/hostdev\[2\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[2\]/@managed=yes
virt-xml "$1" "$FLAGS" --edit --xml 	./devices/hostdev\[2\]/source/address/@bus=0x01

echo "Passing USB"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[3\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[3\]/source/address/@slot=0x14 \
			--xml ./devices/hostdev\[3\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[3\]/@managed=yes

virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[4\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[4\]/source/address/@slot=0x1a \
			--xml ./devices/hostdev\[4\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[4\]/@managed=yes

virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[5\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[5\]/source/address/@slot=0x1b \
			--xml ./devices/hostdev\[5\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[5\]/@managed=yes

virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[6\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[6\]/source/address/@slot=0x1d \
			--xml ./devices/hostdev\[6\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[6\]/@managed=yes

echo "Passing disk drives"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[7\]/@mode=subsystem/@type=scsi \
			--xml 	./devices/hostdev\[7\]/source/adapter/@name=scsi_host2 \
			--xml 	./devices/hostdev\[7\]/source/address/@bus=0 \
			--xml 	./devices/hostdev\[7\]/source/address/@target=0 \
			--xml 	./devices/hostdev\[7\]/source/address/@unit=0 \
			--xml ./devices/hostdev\[7\]/address/@type=drive

virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[8\]/@mode=subsystem/@type=scsi \
			--xml 	./devices/hostdev\[8\]/source/adapter/@name=scsi_host3 \
			--xml 	./devices/hostdev\[8\]/source/address/@bus=0 \
			--xml 	./devices/hostdev\[8\]/source/address/@target=0 \
			--xml 	./devices/hostdev\[8\]/source/address/@unit=0 \
			--xml ./devices/hostdev\[8\]/address\[@type="drive"\]/@unit=1

echo "Changing Hyper-V ID"
virt-xml "$1" "$FLAGS" --edit --xml ./features/hyperv/vendor_id/@state=on \
			--xml ./features/hyperv/vendor_id/@value=kiwifarms

echo "Hiding KVM"
virt-xml "$1" "$FLAGS" --edit --xml ./features/kvm/hidden/@state=on

echo "Setting IOAPIC driver to KVM"
virt-xml "$1" "$FLAGS" --edit --xml ./features/ioapic/@driver=kvm

echo "Disabling memballoon"
virt-xml "$1" "$FLAGS" --edit --memballoon model=none

if ! cat "/etc/libvirt/qemu/$1.xml" | grep "<os firmware=\"efi\">" > /dev/null; then
	echo "Enabling X-VGA"
	virt-xml "$1" "$FLAGS" --edit --xml ./@xmlns:qemu=http://libvirt.org/schemas/domain/qemu/1.0 \
				--xml ./qemu:override/qemu:device/@alias=hostdev0 \
				--xml ./qemu:override/qemu:device/qemu:frontend/qemu:property/@name=x-vga \
				--xml ./qemu:override/qemu:device/qemu:frontend/qemu:property/@type=bool \
				--xml ./qemu:override/qemu:device/qemu:frontend/qemu:property/@value=true
fi
