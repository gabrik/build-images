#!/bin/bash

set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"


docker pull ${IMAGE}
docker run -it -d --name build-os ${IMAGE} bash

# deps
docker exec build-os apt update
docker exec build-os apt install build-essential devscripts lintian dh-make git wget jq python3 python3-dev python3-pip unzip cmake sudo -y
docker exec build-os bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build-os pip3 install pyangbind sphinx zenoh==0.3.0 yaks==0.3.0.post1
docker exec build-os bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/sdk-python -b ${BRANCH} --depth 1 && cd sdk-python && make && make install"
docker exec build-os bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/api-python -b ${BRANCH}  --depth 1 && cd api-python && make install"
# building deb file
docker exec build-os bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/plugin-os-linux  -b ${BRANCH} --depth 1"
docker exec build-os bash -c "mkdir /root/build && cd /root && cp -r plugin-os-linux build/fog05-plugin-os-linux-${VERSION} && cd build/fog05-plugin-os-linux-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-plugin-os-linux-${VERSION}.tar.gz fog05-plugin-os-linux-${VERSION}"
docker exec build-os bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc\" && cd /root/build/fog05-plugin-os-linux-${VERSION} && dh_make -f ../fog05-plugin-os-linux-${VERSION}.tar.gz -s -y"
docker exec -e VERSION=${VERSION}  build-os bash -c 'cd /root/build/fog05-plugin-os-linux-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-os-linux/lib/systemd/system/\n\t\$(MAKE) LINUX_PLUGIN_DIR=\$\$(pwd)/debian/fog05-plugin-os-linux/etc/fos/plugins/plugin-os-linux SYSTEMD_DIR=\$\$(pwd)/debian/fog05-plugin-os-linux/lib/systemd/system/ install">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
docker cp templates/changelog build-os:/root/build/fog05-plugin-os-linux-${VERSION}/debian/changelog
docker cp templates/postinst build-os:/root/build/fog05-plugin-os-linux-${VERSION}/debian/postinst
docker cp templates/control build-os:/root/build/fog05-plugin-os-linux-${VERSION}/debian/control
docker cp templates/copyright build-os:/root/build/fog05-plugin-os-linux-${VERSION}/debian/copyright

docker exec build-os bash -c "cd /root/build/fog05-plugin-os-linux-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
docker exec build-os bash -c "cd /root/build/ && dpkg -I fog05-plugin-os-linux_${VERSION}-1_amd64.deb"
docker cp build-os:/root/build/fog05-plugin-os-linux_${VERSION}-1_amd64.deb ../fog05-plugin-os-linux_${VERSION}-1_amd64_${IMAGE}.deb

docker container rm --force build-os