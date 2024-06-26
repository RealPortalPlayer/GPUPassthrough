#!/usr/bin/python3
import os
import sys
import argparse
from xml.etree import ElementTree

config_path = '/etc/libvirt/qemu'
units = {
    'b': 1,
    'bytes': 1,
    'KB': 10**3,
    'k': 2**10,
    'KiB': 2**10,
    'MB': 10**6,
    'M': 2**20,
    'MiB': 2**20,
    'GB': 10**9,
    'G': 2**30,
    'GiB': 2**30,
    'TB': 10**12,
    'T': 2**40,
    'TiB': 2**40
}

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('vm_name')
    args = parser.parse_args()
    with open(os.path.join(config_path, args.vm_name + '.xml')) as fp:
        vm_xml = ElementTree.fromstringlist(fp.read())
        if vm_xml.find('./memoryBacking/hugepages') is not None:
            mem = vm_xml.find('./memory')
            try:
                multipier = units[mem.attrib['unit']]
            except KeyError:
                multipier = 1
            print(int(mem.text) * multipier)
            sys.exit(0)
    sys.exit(-1)
