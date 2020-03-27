#!/bin/bash

set -e

# UBUNTU="ubuntu:bionic"
# DEBIAN="debian:10-slim"

lxc launch images:${IMAGE} build
sleep 2
# install deps
lxc exec build -- apt update
lxc exec build -- apt install build-essential devscripts lintian dh-make git python3 python3-dev python3-pip unzip sudo python3-all python-all cmake wget -y
lxc exec build -- pip3 install pyangbind sphinx stdeb
lxc exec build -- bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
lxc exec build -- bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-python -b 0.3.0 --depth 1 && cd zenoh-python && python3 setup.py install"
lxc exec build -- bash -c "cd /root/ && git clone https://github.com/atolab/yaks-python -b 0.3.0 --depth 1 && cd yaks-python && make install"

# clone repo
lxc exec build -- bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/api-python -b ${BRANCH} --depth 1 fog05-api-${VERSION}"

# normalize version to facilitate build
lxc exec --env VERSION=${VERSION} build -- bash -c 'sed -i "s/0.2.0a/${VERSION}/g" /root/fog05-api-${VERSION}/setup.py'

# building a debian package
lxc exec build -- bash -c "cd /root && mkdir build && tar -czvf build/fog05-api-${VERSION}.tar.gz fog05-api-${VERSION}"
lxc exec build -- bash -c "cd /root/build && py2dsc fog05-api-${VERSION}.tar.gz"
lxc exec build -- bash -c "cd /root/build/deb_dist/fog05-${VERSION} && dpkg-buildpackage -rfakeroot -uc -us"
lxc exec build -- bash -c "cd /root/build/deb_dist/ && dpkg -I python3-fog05_${VERSION}-1_all.deb"



lxc file pull build/root/build/deb_dist/python3-fog05_${VERSION}-1_all.deb ../python3-fog05_${VERSION}-1_all.deb

lxc delete --force build