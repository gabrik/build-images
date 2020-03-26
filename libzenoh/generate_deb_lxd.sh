#!/bin/bash

set -e

# UBUNTU="ubuntu:bionic"
# DEBIAN="debian:10-slim"

lxc launch images:${IMAGE} build
sleep 2
# install deps
lxc exec build -- apt update
lxc exec build -- apt apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo -y

# clone repo
lxc exec build -- bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1"
# building a debian package
lxc file push templates/CMakeLists.txt build/root/zenoh-c/CMakeLists.txt

lxc exec build -- bash -c "cd /root/zenoh-c && make && cd build && cpack"
lxc exec build -- bash -c "cd /root/zenoh-c/build/ && dpkg -I libzenoh-0.3.0-Linux.deb"
lxc exec build -- bash -c "cd /root/build && py2dsc fog05-sdk-${VERSION}.tar.gz"
lxc exec build -- bash -c "cd /root/build/deb_dist/fog05-sdk-${VERSION} && dpkg-buildpackage -rfakeroot -uc -us"
lxc exec build -- bash -c "cd /root/build/deb_dist/ && dpkg -I python3-fog05-sdk_${VERSION}-1_all.deb"

lxc file pull build/root/zenoh-c/build/libzenoh-0.3.0-Linux.deb ../libzenoh-0.3.0-Linux.deb

lxc delete --force build