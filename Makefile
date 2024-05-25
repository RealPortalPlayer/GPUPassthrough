all:
	cp virt-listall.sh /usr/local/bin/virt-listall
	cp virt-listgpu.sh /usr/local/bin/virt-listgpu
	cp virt-listgpu2.sh /usr/local/bin/virt-listgpu2
	mkdir -p /etc/libvirt/hooks
	cp qemu.sh /etc/libvirt/hooks/qemu
	cp nvidia.rom /etc
	cp gt220.rom /etc
	cp agpu.sh /usr/local/bin/agpu
	cp rgpu.sh /usr/local/bin/rgpu
	cp agpu2.sh /usr/local/bin/agpu2
	cp rgpu2.sh /usr/local/bin/rgpu2
	cp vm-mem-requirements.py3 /etc/libvirt/hooks/vm-mem-requirements 
	chmod 755 /usr/local/bin/virt-listall
	chmod 755 /usr/local/bin/virt-listgpu
	chmod 755 /etc/nvidia.rom
	chmod 755 /etc/gt220.rom
	chmod 755 /usr/local/bin/agpu
	chmod 755 /usr/local/bin/rgpu

