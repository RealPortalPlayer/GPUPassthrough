#!/bin/bash
if [ $# -eq 0 ]; then
	echo "Usage: $0 <vm name>"
	exit 1
fi

if ! /usr/local/bin/virt-listgpu "$1" > /dev/null; then
	echo "The VM doesn't have the GPU passed through"
	exit 1
fi

echo "Reverting CPU topology"
virt-xml "$1" -q --edit --vcpus sockets=1,dies=1,cores=1,threads=1,maxvcpus=1

echo "Disabling Hugepages"
virt-xml "$1" -q --edit --memorybacking hugepages=off

echo "Reverting CPU pinning"
virt-xml "$1" -q --edit --xml xpath.delete=./cputune

echo "Reverting RAM"
virt-xml "$1" -q --edit --memory 4024

echo "Removing virtual serial"
virt-xml "$1" -q --remove-device --serial all

echo "Removing host devices"
virt-xml "$1" -q --remove-device --hostdev all

echo "Reverting Hyper-V ID"
virt-xml "$1" -q --edit --xml xpath.delete=./features/hyperv/vendor_id

echo "Unhiding KVM"
virt-xml "$1" -q --edit --xml xpath.delete=./features/kvm

echo "Reverting IOAPIC driver"
virt-xml "$1" -q --edit --xml xpath.delete=./features/ioapic

if ! cat "/etc/libvirt/qemu/$1.xml" | grep "<os firmware=\"efi\">" > /dev/null; then
	echo "Disabling X-VGA"
	virt-xml "$1" -q --edit --xml xpath.delete=./qemu:override
fi
