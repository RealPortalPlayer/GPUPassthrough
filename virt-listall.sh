#!/bin/bash
ls -1 /etc/libvirt/qemu/*.xml | while read line; do
	line=`basename $line .xml`
	if [ -n "$line" ]; then
		echo "$line"
	fi
done
