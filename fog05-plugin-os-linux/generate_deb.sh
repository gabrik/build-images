#!/bin/bash

set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull $DEBIAN
docker run -it -d --name build $DEBIAN bash
# deps
docker exec build apt update
docker exec build apt install build-essential devscripts lintian dh-make git wget jq python3 python3-dev python3-pip unzip cmake sudo -y
docker exec build pip3 install pyangbind sphinx
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-python -b 0.3.0 --depth 1 && cd zenoh-python && python3 setup.py install"
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/yaks-python -b 0.3.0 --depth 1 && cd yaks-python && make install"
docker exec build bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/sdk-python -b 0.1 --depth 1 && cd sdk-python && make && make install"
docker exec build bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/api-python -b 0.1 --depth 1 && cd api-python && make install"
# building deb file
docker exec build bash -c "cd /root/ && git clone https://github.com/gabrik/plugin-os-linux"
docker exec build bash -c "mkdir /root/build && cd /root && cp -r plugin-os-linux build/fog05-plugin-os-linux-0.1 && cd build/fog05-plugin-os-linux-0.1 && rm -rf .git && make clean && cd .. && tar -czvf fog05-plugin-os-linux-0.1.tar.gz fog05-plugin-os-linux-0.1"
docker exec build bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc\" && cd /root/build/fog05-plugin-os-linux-0.1 && dh_make -f ../fog05-plugin-os-linux-0.1.tar.gz -s -y"
docker exec build bash -c 'cd /root/build/fog05-plugin-os-linux-0.1 && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-os-linux/lib/systemd/system/\n\t\$(MAKE) LINUX_PLUGIN_DIR=\$\$(pwd)/debian/fog05-plugin-os-linux/etc/fos/plugins/plugin-os-linux SYSTEMD_DIR=\$\$(pwd)/debian/fog05-plugin-os-linux/lib/systemd/system/ install">> debian/rules'
docker cp templates/changelog build:/root/build/fog05-plugin-os-linux-0.1/debian/changelog
docker cp templates/postinst build:/root/build/fog05-plugin-os-linux-0.1/debian/postinst
docker cp templates/control build:/root/build/fog05-plugin-os-linux-0.1/debian/control
docker cp templates/copyright build:/root/build/fog05-plugin-os-linux-0.1/debian/copyright

docker exec build bash -c "cd /root/build/fog05-plugin-os-linux-0.1 && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
docker exec build bash -c "cd /root/build/ && dpkg -I fog05-plugin-os-linux_0.1-1_amd64.deb"
docker cp build:/root/build/fog05-plugin-os-linux_0.1-1_amd64.deb ../fog05-plugin-os-linux_0.1-1_amd64_debian_buster.deb

docker container rm --force build