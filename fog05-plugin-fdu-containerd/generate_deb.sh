#!/bin/bash

set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull $DEBIAN
docker run -it -d --name build $DEBIAN bash
docker exec build apt update
# install deps
docker exec build apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo -y
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build bash -c "cd /root/ && wget https://dl.google.com/go/go1.13.8.linux-amd64.tar.gz && tar -C /usr/local -xzf  go1.13.8.linux-amd64.tar.gz"
# cloning repo inside container
docker exec build bash -c "cd /root && git clone https://github.com/eclipse-fog05/plugin-fdu-containerd"

docker exec build bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/plugin-fdu-containerd && make && ldd plugin"
docker exec build bash -c "mkdir /root/build && cd /root && cp -r plugin-fdu-containerd build/fog05-plugin-fdu-containerd-0.1 && cd build/fog05-plugin-fdu-containerd-0.1 && rm -rf .git && make clean && cd .. && tar -czvf fog05-plugin-fdu-containerd-0.1.tar.gz fog05-plugin-fdu-containerd-0.1"
docker exec build bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ATO Labs\" && cd /root/build/fog05-plugin-fdu-containerd-0.1 && dh_make -f ../fog05-plugin-fdu-containerd-0.1.tar.gz -s -y"
docker exec build bash -c 'cd /root/build/fog05-plugin-fdu-containerd-0.1 && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-fdu-containerd/lib/systemd/system/\n\t\$(MAKE) CTD_PLUGIN_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-containerd/etc/fos/plugins/plugin-fdu-containerd SYSTEMD_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-containerd/lib/systemd/system/ install">> debian/rules'

docker cp templates/changelog build:/root/build/fog05-plugin-fdu-containerd-0.1/debian/changelog
docker cp templates/postinst build:/root/build/fog05-plugin-fdu-containerd-0.1/debian/postinst
docker cp templates/control build:/root/build/fog05-plugin-fdu-containerd-0.1/debian/control
docker cp templates/copyright build:/root/build/fog05-plugin-fdu-containerd-0.1/debian/copyright

docker exec build bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/build/fog05-plugin-fdu-containerd-0.1 && debuild --preserve-envvar PATH -us -uc  && ls -l"
docker exec build bash -c "cd /root/build/ && dpkg -I fog05-plugin-fdu-containerd_0.1-1_amd64.deb"

docker cp build:/root/build/fog05-plugin-fdu-containerd_0.1-1_amd64.deb ../fog05-plugin-fdu-containerd_0.1-1_amd64_debian_buster.deb

docker container rm --force build