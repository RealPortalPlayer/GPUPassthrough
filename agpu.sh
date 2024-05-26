#!/bin/bash
TEMPORARY_ROM_PATH="TEMPORARY_PATH_TEMPORARY_PATH_HACK_TEMPORARY_PATH_WILL_BE_REPLACED"

if [ $# -eq 0 ]; then
	echo "Usage: $0 <vm name>"
	exit 1
fi

FLAGS="-q"
BUS="0x01"
ROM="nvidia.rom"

if [ "$DEBUG" == "1" ]; then
	FLAGS="-d"
fi

if [ "$SECOND_GPU" == "1" ]; then
	BUS="0x05"
	ROM="gt220.rom"
fi

if /usr/local/bin/virt-listgpu "$1" > /dev/null; then
	echo "The VM already has the GPU passed through"
	exit 1
fi

if cat "/etc/libvirt/qemu/$1.xml" | grep "machine='pc-i440fx-" > /dev/null; then
	echo "Warning, i440fx does not support PCI, please use q35"
fi

if ! cat "/etc/libvirt/qemu/$1.xml" | grep "arch='x86_64'" > /dev/null; then
	echo "Warning, invalid architecture. Unknown PCI passthrough support, and potential slow emulation negating PCI passthrough benefits"
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

if [ "$SECOND_GPU" != "1" ]; then
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
fi

echo "Setting RAM"
virt-xml "$1" "$FLAGS" --edit --memory 16024

if [ "$SECOND_GPU" == "1" ]; then
	echo "Passing PS/2 keyboard"
	virt-xml "$1" "$FLAGS" --add-device --input type="evdev",source.dev=/dev/input/by-path/platform-i8042-serio-0-event-kbd,source.grab="all",source.repeat="on",source.grabToggle="ctrl-ctrl"

	echo "Passing PS/2 mouse"
	virt-xml "$1" "$FLAGS" --add-device --input type="evdev",source.dev=/dev/input/by-path/platform-i8042-serio-1-event-mouse
else
	echo "Passing PS/2 keyboard"
	virt-xml "$1" "$FLAGS" --add-device --input type="keyboard",bus="$INPUT_BUS",address.type="pci",address.domain="0x0000",address.bus="0x00",address.slot="0x0f",address.function="0x0"
	
	echo "Passing PS/2 mouse"
	virt-xml "$1" "$FLAGS" --add-device --input type="mouse",bus="$INPUT_BUS",address.type="pci",address.domain="0x0000",address.bus="0x00",address.slot="0x0e",address.function="0x0"
fi

echo "Passing GPU"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[1\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[1\]/source/address/@bus=$BUS \
			--xml ./devices/hostdev\[1\]/rom/@file="$TEMPORARY_ROM_PATH" \
			--xml ./devices/hostdev\[1\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[1\]/@managed=yes

echo "Fixing ROM path"
sed -i "s/$TEMPORARY_ROM_PATH/\/etc\/$ROM/" "/etc/libvirt/qemu/$1.xml"

echo "Reloading modified XML file"
sudo virsh "$FLAGS" define "/etc/libvirt/qemu/$1.xml"

echo "Passing GPU audio"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[2\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[2\]/source/address/@function=0x01 \
			--xml ./devices/hostdev\[2\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[2\]/@managed=yes
virt-xml "$1" "$FLAGS" --edit --xml 	./devices/hostdev\[2\]/source/address/@bus=$BUS

echo "Passing USB"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[3\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[3\]/source/address/@slot=0x14 \
			--xml ./devices/hostdev\[3\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[3\]/@managed=yes

virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[4\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[4\]/source/address/@slot=0x1a \
			--xml ./devices/hostdev\[4\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[4\]/@managed=yes

FIRST="5"
SECOND="6"
THIRD="7"

if [ "$SECOND_GPU" != "1" ]; then
	FIRST="6"
	SECOND="7"
	THIRD="8"

	virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[5\]/@mode=subsystem/@type=pci \
				--xml 	./devices/hostdev\[5\]/source/address/@slot=0x1b \
				--xml ./devices/hostdev\[5\]/address/@type=pci
	virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[5\]/@managed=yes
fi

virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[$FIRST\]/@mode=subsystem/@type=pci \
			--xml 	./devices/hostdev\[$FIRST\]/source/address/@slot=0x1d \
			--xml ./devices/hostdev\[$FIRST\]/address/@type=pci
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[$FIRST\]/@managed=yes

echo "Passing disk drives"
virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[$SECOND\]/@mode=subsystem/@type=scsi \
			--xml 	./devices/hostdev\[$SECOND\]/source/adapter/@name=scsi_host2 \
			--xml 	./devices/hostdev\[$SECOND\]/source/address/@bus=0 \
			--xml 	./devices/hostdev\[$SECOND\]/source/address/@target=0 \
			--xml 	./devices/hostdev\[$SECOND\]/source/address/@unit=0 \
			--xml ./devices/hostdev\[$SECOND\]/address/@type=drive

virt-xml "$1" "$FLAGS" --edit --xml ./devices/hostdev\[$THIRD\]/@mode=subsystem/@type=scsi \
			--xml 	./devices/hostdev\[$THIRD\]/source/adapter/@name=scsi_host3 \
			--xml 	./devices/hostdev\[$THIRD\]/source/address/@bus=0 \
			--xml 	./devices/hostdev\[$THIRD\]/source/address/@target=0 \
			--xml 	./devices/hostdev\[$THIRD\]/source/address/@unit=0 \
			--xml ./devices/hostdev\[$THIRD\]/address\[@type="drive"\]/@unit=1

echo "Changing Hyper-V ID"
virt-xml "$1" "$FLAGS" --edit --xml ./features/hyperv/vendor_id/@state=on \
			--xml ./features/hyperv/vendor_id/@value=kiwifarms

echo "Hiding KVM"
virt-xml "$1" "$FLAGS" --edit --xml ./features/kvm/hidden/@state=on

echo "Setting IOAPIC driver to KVM"
virt-xml "$1" "$FLAGS" --edit --xml ./features/ioapic/@driver=kvm

echo "Disabling memballoon"
virt-xml "$1" "$FLAGS" --edit --memballoon model=none

if ! cat "/etc/libvirt/qemu/$1.xml" | grep -E "<os firmware=('efi'|\"efi\")>" > /dev/null; then
	echo "Enabling X-VGA"
	virt-xml "$1" "$FLAGS" --edit --xml ./@xmlns:qemu=http://libvirt.org/schemas/domain/qemu/1.0 \
				--xml ./qemu:override/qemu:device/@alias=hostdev0 \
				--xml ./qemu:override/qemu:device/qemu:frontend/qemu:property/@name=x-vga \
				--xml ./qemu:override/qemu:device/qemu:frontend/qemu:property/@type=bool \
				--xml ./qemu:override/qemu:device/qemu:frontend/qemu:property/@value=true
fi

if [ "$SECOND_GPU" == "1" ]; then
	echo "Adding headless display"
	virt-xml "$1" "$FLAGS" --add-device --video model.type="none" 

	echo "Passing VM audio to PipeWire"
	virt-xml "$1" "$FLAGS" --edit --xml ./devices/audio/@id="1"
	virt-xml "$1" "$FLAGS" --edit --xml ./devices/audio/@type="pipewire"
	virt-xml "$1" "$FLAGS" --edit --xml ./devices/audio/@runtimeDir="/run/user/1000"
	virt-xml "$1" "$FLAGS" --edit --xml ./devices/audio/input/@name="$1input"
	virt-xml "$1" "$FLAGS" --edit --xml ./devices/audio/output/@name="$1output"

	echo "Setting audio to AC97"
	virt-xml "$1" "$FLAGS" --add-device --sound model="ac97"
fi
