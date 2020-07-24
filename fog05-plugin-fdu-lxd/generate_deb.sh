#!/bin/bash

set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull ${IMAGE}
docker run -it -d --name build-lxd ${IMAGE} bash
# export CODENAME=$(docker exec build-lxd bash -c "lsb_release -c -s")
# deps
docker exec build-lxd apt update
docker exec build-lxd apt install build-essential devscripts lintian dh-make git wget jq python3 python3-dev python3-pip unzip cmake sudo -y
docker exec build-lxd bash -c "id -u fos  >/dev/null 2>&1 ||  sudo useradd -r -s /bin/false fos"
docker exec build-lxd groupadd lxd
docker exec build-lxd bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build-lxd pip3 install pyangbind sphinx zenoh==0.3.0 yaks==0.3.0.post1
docker exec build-lxd bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/sdk-python -b ${BRANCH} --depth 1 && cd sdk-python && make && make install"
docker exec build-lxd bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/api-python -b ${BRANCH}  --depth 1 && cd api-python && make install"
# building deb file
docker exec build-lxd bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/plugin-fdu-lxd -b ${BRANCH} --depth 1"
docker exec build-lxd bash -c "mkdir /root/build && cd /root && cp -r plugin-fdu-lxd build/fog05-plugin-fdu-lxd-${VERSION} && cd build/fog05-plugin-fdu-lxd-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-plugin-fdu-lxd-${VERSION}.tar.gz fog05-plugin-fdu-lxd-${VERSION}"
docker exec build-lxd bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc\" && cd /root/build/fog05-plugin-fdu-lxd-${VERSION} && dh_make -f ../fog05-plugin-fdu-lxd-${VERSION}.tar.gz -s -y"
docker exec -e VERSION=${VERSION} build-lxd bash -c 'cd /root/build/fog05-plugin-fdu-lxd-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-fdu-lxd/lib/systemd/system/\n\t\$(MAKE) LXD_PLUGIN_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-lxd/etc/fos/plugins/plugin-fdu-lxd SYSTEMD_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-lxd/lib/systemd/system/ install">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
docker cp templates/changelog build-lxd:/root/build/fog05-plugin-fdu-lxd-${VERSION}/debian/changelog
docker cp templates/postinst build-lxd:/root/build/fog05-plugin-fdu-lxd-${VERSION}/debian/postinst
docker cp templates/postrm build-lxd:/root/build/fog05-plugin-fdu-lxd-${VERSION}/debian/postrm
docker cp templates/control build-lxd:/root/build/fog05-plugin-fdu-lxd-${VERSION}/debian/control
docker cp templates/copyright build-lxd:/root/build/fog05-plugin-fdu-lxd-${VERSION}/debian/copyright

docker exec build-lxd bash -c "cd /root/build/fog05-plugin-fdu-lxd-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
docker exec build-lxd bash -c "cd /root/build/ && dpkg -I fog05-plugin-fdu-lxd_${VERSION}-1_amd64.deb"
docker cp build-lxd:/root/build/fog05-plugin-fdu-lxd_${VERSION}-1_amd64.deb ../fog05-plugin-fdu-lxd_${VERSION}-1_amd64.deb

docker container rm --force build-lxd


set +x
echo $KEY  | base64 --decode > key
chmod 0600 key
scp -o StrictHostKeyChecking=no -i ./key ../fog05-plugin-fdu-lxd_${VERSION}-1_amd64.deb $USER@$SERVER:$DEPLOYDIR/fos/deb/bionic/amd64/fog05-plugin-fdu-lxd-1_amd64.deb
rm key
set -x