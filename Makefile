all:
	cp virt-listall.sh /usr/local/bin/virt-listall
	cp virt-listgpu.sh /usr/local/bin/virt-listgpu
	mkdir -p /etc/libvirt/hooks
	cp qemu.sh /etc/libvirt/hooks
	cp nvidia.rom /etc
	cp gt220.rom /etc
