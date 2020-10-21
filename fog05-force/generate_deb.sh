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
docker run -it -d --name build-force ${IMAGE} bash
# export CODENAME=$(docker exec build-force bash -c "lsb_release -c -s")
docker exec build-force apt update
# install deps
docker exec build-force apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo -y
docker exec build-force bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build-force bash -c "cd /root/ && wget https://golang.org/dl/go1.15.3.linux-arm64.tar.gz && tar -C /usr/local -xzf  go1.15.3.linux-arm64.tar.gz"
# cloning repo inside container
docker exec build-force bash -c "cd /root && git clone https://github.com/eclipse-fog05/fog05/ -b ${BRANCH} --depth 1"

docker cp templates/Makefile build-force:/root/fog05/src/force/Makefile
docker cp templates/force.service build-force:/root/fog05/src/force/force.service
docker exec build-force bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/fog05/src/force && make"
docker exec build-force bash -c "mkdir /root/build && cd /root && cp -r /root/fog05/src/force build/fog05-force-${VERSION} && cd build/fog05-force-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-force-${VERSION}.tar.gz fog05-force-${VERSION}"
docker exec build-force bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ATO Labs\" && cd /root/build/fog05-force-${VERSION} && dh_make -f ../fog05-force-${VERSION}.tar.gz -s -y"
docker exec -e VERSION=${VERSION} build-force bash -c 'cd /root/build/fog05-force-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p $$(pwd)/debian/fog05-force/usr/local/bin\n\tmkdir -p $$(pwd)/debian/fog05-force/etc/fos/\n\tmkdir -p \$\$(pwd)/debian/fog05-force/lib/systemd/system/\n\t\$(MAKE) FORCE_DIR=\$\$(pwd)/debian/fog05-force/etc/fos/ SYSTEMD_DIR=\$\$(pwd)/debian/fog05-force/lib/systemd/system/ LOCAL_BIN=\$\$(pwd)/debian/fog05-force/usr/local/bin install">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
docker cp templates/changelog build-force:/root/build/fog05-force-${VERSION}/debian/changelog
docker cp templates/control build-force:/root/build/fog05-force-${VERSION}/debian/control
docker cp templates/postinst build-force:/root/build/fog05-force-${VERSION}/debian/postinst
docker cp templates/postrm build-force:/root/build/fog05-force-${VERSION}/debian/postrm
docker cp templates/copyright build-force:/root/build/fog05-force-${VERSION}/debian/copyright

docker exec build-force bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/build/fog05-force-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l"
docker exec build-force bash -c "cd /root/build/ && dpkg -I fog05-force_${VERSION}-1_amd64.deb"

docker cp build-force:/root/build/fog05-force_${VERSION}-1_amd64.deb ../fog05-force_${VERSION}-1_amd64.deb

docker container rm --force build-force

if [ "$UPLOAD" = true ]; then
    set +x
    echo $KEY  | base64 --decode > key
    chmod 0600 key
    scp -o StrictHostKeyChecking=no -i ./key ../fog05-force_${VERSION}-1_amd64.deb $USER@$SERVER:$DEPLOYDIR/fos/deb/bionic/amd64/fog05-force-1_amd64.deb
    rm key
    set -x
fi
