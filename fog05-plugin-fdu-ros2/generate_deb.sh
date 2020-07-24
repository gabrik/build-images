#!/bin/bash

set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull ${IMAGE}
docker run -it -d --name build-ros ${IMAGE} bash
# export CODENAME=$(docker exec build-ros bash -c "lsb_release -c -s")
# deps
docker exec build-ros apt update
docker exec build-ros apt install build-essential devscripts lintian dh-make git wget jq python3 python3-dev python3-pip unzip cmake sudo -y
docker exec build-ros pip3 install pyangbind sphinx
docker exec build-ros bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build-ros bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-python -b 0.3.0 --depth 1 && cd zenoh-python && python3 setup.py install"
docker exec build-ros bash -c "cd /root/ && git clone https://github.com/atolab/yaks-python -b 0.3.0 --depth 1 && cd yaks-python && make install"
docker exec build-ros bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/sdk-python -b master --depth 1 && cd sdk-python && make && make install"
docker exec build-ros bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/api-python -b master --depth 1 && cd api-python && make install"
# building deb file
docker exec build-ros bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/plugin-fdu-ros2  -b ${BRANCH} --depth 1"
docker exec build-ros bash -c "mkdir /root/build && cd /root && cp -r plugin-fdu-ros2 build/fog05-plugin-fdu-ros2-${VERSION} && cd build/fog05-plugin-fdu-ros2-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-plugin-fdu-ros2-${VERSION}.tar.gz fog05-plugin-fdu-ros2-${VERSION}"
docker exec build-ros bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc\" && cd /root/build/fog05-plugin-fdu-ros2-${VERSION} && dh_make -f ../fog05-plugin-fdu-ros2-${VERSION}.tar.gz -s -y"
docker exec  -e VERSION=${VERSION} build-ros bash -c 'cd /root/build/fog05-plugin-fdu-ros2-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-fdu-ros2/lib/systemd/system/\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-fdu-ros2/usr/bin/\n\t\$(MAKE) ROS2_PLUGIN_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-ros2/etc/fos/plugins/plugin-fdu-ros2 SYSTEMD_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-ros2/lib/systemd/system/ BIN_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-ros2/usr/bin install">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
docker cp templates/changelog build-ros:/root/build/fog05-plugin-fdu-ros2-${VERSION}/debian/changelog
docker cp templates/postinst build-ros:/root/build/fog05-plugin-fdu-ros2-${VERSION}/debian/postinst
docker cp templates/control build-ros:/root/build/fog05-plugin-fdu-ros2-${VERSION}/debian/control
docker cp templates/copyright build-ros:/root/build/fog05-plugin-fdu-ros2-${VERSION}/debian/copyright

docker exec build-ros bash -c "cd /root/build/fog05-plugin-fdu-ros2-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
docker exec build-ros bash -c "cd /root/build/ && dpkg -I fog05-plugin-fdu-ros2_${VERSION}-1_amd64.deb"
docker cp build-ros:/root/build/fog05-plugin-fdu-ros2_${VERSION}-1_amd64.deb ../fog05-plugin-fdu-ros2_${VERSION}-1_amd64.deb

docker container rm --force build-ros



set +x
echo $KEY  | base64 --decode > key
chmod 0600 key
scp -o StrictHostKeyChecking=no -i ./key ../fog05-plugin-fdu-ros2_${VERSION}-1_amd64.deb $USER@$SERVER:$DEPLOYDIR/fos/deb/bionic/amd64/fog05-plugin-fdu-ros2-1_amd64.deb
rm key
set -x