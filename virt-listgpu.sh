#!/bin/bash
if [ "$#" -ne 0 ]; then
	while read line; do
		if [ "$line" = "$1" ]; then
			exit
		fi
	done <<< `/usr/local/bin/virt-listgpu`
	
	exit 1
fi

BUS="0x01"

if [ "$SECOND_GPU" = "1" ]; then
	BUS="0x05"
fi

/usr/local/bin/virt-listall | while read line; do
	if sudo cat /etc/libvirt/qemu/$line.xml | grep "<address domain='0x0000' bus='$BUS' slot='0x00' function='0x0'/>" > /dev/null; then
		echo "$line"
	fi
done
