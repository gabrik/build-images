#!/bin/bash
set -e

dpkg -b fog05_0.1-1
dpkg -b fog05-plugin-net-linuxbridge_0.1-1
dpkg -b fog05-plugin-fdu-native_0.1-1
dpkg -b fog05-plugin-fdu-lxd_0.1-1
dpkg -b fog05-plugin-fdu-kvm_0.1-1
dpkg -b libzenoh-dev_0.0.1-1

mkdir debs
mv *.deb debs/

exit 0