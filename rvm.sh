#!/bin/bash
echo "Main GPU:"
sudo /usr/local/bin/virt-listgpu

echo
echo "Second GPU:"
sudo /usr/local/bin/virt-listgpu2

printf "Selection: "
read -r selection

if [ -z "$selection" ]; then
	echo "Please make a selection"
	exit 1
fi

if ! /usr/local/bin/virt-listgpu "$selection" && ! /usr/local/bin/virt-listgpu2 "$selection"; then
	echo "Invalid selection: $selection"
	exit 1
fi

sudo virsh start "$selection"
