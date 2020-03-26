#!/bin/bash

set -e

# UBUNTU="ubuntu:bionic"
# DEBIAN="debian:10-slim"

lxc launch images:${IMAGE} build
sleep 2
# install deps
lxc exec build -- apt update
lxc exec build -- apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo -y
lxc exec build -- bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
lxc exec build -- bash -c "cd /root/ && wget https://dl.google.com/go/go1.13.8.linux-amd64.tar.gz && tar -C /usr/local -xzf  go1.13.8.linux-amd64.tar.gz"
# clone repo
lxc exec build -- bash -c "cd /root && git clone https://github.com/eclipse-fog05/plugin-fdu-containerd -b ${BRANCH} --depth 1"
# building a debian package
lxc exec build -- bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/plugin-fdu-containerd && make && ldd plugin"
lxc exec build -- bash -c "mkdir /root/build && cd /root && cp -r plugin-fdu-containerd build/fog05-plugin-fdu-containerd-${VERSION} && cd build/fog05-plugin-fdu-containerd-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-plugin-fdu-containerd-${VERSION}.tar.gz fog05-plugin-fdu-containerd-${VERSION}"
lxc exec build -- bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ATO Labs\" && cd /root/build/fog05-plugin-fdu-containerd-${VERSION} && dh_make -f ../fog05-plugin-fdu-containerd-${VERSION}.tar.gz -s -y"
lxc exec --env VERSION=${VERSION} build -- bash -c 'cd /root/build/fog05-plugin-fdu-containerd-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-fdu-containerd/lib/systemd/system/\n\t\$(MAKE) CTD_PLUGIN_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-containerd/etc/fos/plugins/plugin-fdu-containerd SYSTEMD_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-containerd/lib/systemd/system/ install">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
lxc file push templates/changelog build/root/build/fog05-plugin-fdu-containerd-${VERSION}/debian/changelog
lxc file push templates/postinst build/root/build/fog05-plugin-fdu-containerd-${VERSION}/debian/postinst
lxc file push templates/control build/root/build/fog05-plugin-fdu-containerd-${VERSION}/debian/control
lxc file push templates/copyright build/root/build/fog05-plugin-fdu-containerd-${VERSION}/debian/copyright

lxc exec build -- bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/build/fog05-plugin-fdu-containerd-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l"
lxc exec build -- bash -c "cd /root/build/ && dpkg -I fog05-plugin-fdu-containerd_${VERSION}-1_amd64.deb"


lxc file pull build/root/build/fog05-plugin-fdu-containerd_${VERSION}-1_amd64.deb ../fog05-plugin-fdu-containerd_${VERSION}-1_amd64_${IMAGE}.deb

lxc delete --force build