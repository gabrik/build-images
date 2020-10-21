#!/bin/bash

set -e

if [[ -z "${DEPLOY}" ]]; then
  UPLOAD=false
else
  UPLOAD=true
fi

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull ${IMAGE}
docker run -it -d --name build-lb ${IMAGE} bash
# deps
docker exec build-lb apt update
docker exec build-lb apt install build-essential devscripts lintian dh-make git wget jq python3 python3-dev python3-pip unzip cmake sudo libxml2-dev libxslt-dev -y
docker exec build-lb bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build-lb pip3 install pyangbind sphinx zenoh==0.3.0 yaks==0.3.0.post1
docker exec build-lb bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/sdk-python -b ${BRANCH} --depth 1 && cd sdk-python && make && make install"
docker exec build-lb bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/api-python -b ${BRANCH}  --depth 1 && cd api-python && make install"
# building deb file
docker exec build-lb bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/plugin-net-linuxbridge  -b ${BRANCH} --depth 1"
docker exec build-lb bash -c "mkdir /root/build && cd /root && cp -r plugin-net-linuxbridge build/fog05-plugin-net-linuxbridge-${VERSION} && cd build/fog05-plugin-net-linuxbridge-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-plugin-net-linuxbridge-${VERSION}.tar.gz fog05-plugin-net-linuxbridge-${VERSION}"
docker exec build-lb bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc\" && cd /root/build/fog05-plugin-net-linuxbridge-${VERSION} && dh_make -f ../fog05-plugin-net-linuxbridge-${VERSION}.tar.gz -s -y"
docker exec -e VERSION=${VERSION} build-lb bash -c 'cd /root/build/fog05-plugin-net-linuxbridge-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-net-linuxbridge/lib/systemd/system/\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-net-linuxbridge/usr/bin\n\t\$(MAKE) LB_PLUGIN_DIR=\$\$(pwd)/debian/fog05-plugin-net-linuxbridge/etc/fos/plugins/plugin-net-linuxbridge SYSTEMD_DIR=\$\$(pwd)/debian/fog05-plugin-net-linuxbridge/lib/systemd/system/ BIN_DIR=\$\$(pwd)/debian/fog05-plugin-net-linuxbridge/usr/bin install">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
docker cp templates/changelog build-lb:/root/build/fog05-plugin-net-linuxbridge-${VERSION}/debian/changelog
docker cp templates/postinst build-lb:/root/build/fog05-plugin-net-linuxbridge-${VERSION}/debian/postinst
docker cp templates/postrm build-lb:/root/build/fog05-plugin-net-linuxbridge-${VERSION}/debian/postrm
docker cp templates/control build-lb:/root/build/fog05-plugin-net-linuxbridge-${VERSION}/debian/control
docker cp templates/copyright build-lb:/root/build/fog05-plugin-net-linuxbridge-${VERSION}/debian/copyright

docker exec build-lb bash -c "cd /root/build/fog05-plugin-net-linuxbridge-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
docker exec build-lb bash -c "cd /root/build/ && dpkg -I fog05-plugin-net-linuxbridge_${VERSION}-1_arm64.deb"
docker cp build-lb:/root/build/fog05-plugin-net-linuxbridge_${VERSION}-1_arm64.deb ../fog05-plugin-net-linuxbridge_${VERSION}-1_arm64.deb

docker container rm --force build-lb



if [ "$UPLOAD" = true ]; then
    set +x
    echo $KEY  | base64 --decode > key
    chmod 0600 key
    scp -o StrictHostKeyChecking=no -i ./key ../fog05-plugin-net-linuxbridge_${VERSION}-1_arm64.deb $USER@$SERVER:$DEPLOYDIR/fos/deb/bionic/arm64/fog05-plugin-net-linuxbridge-1_arm64.deb
    rm key
    set -x
fi