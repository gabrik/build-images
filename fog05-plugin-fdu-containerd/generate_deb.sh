#!/bin/bash

set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull ${IMAGE}
docker run -it -d --name build-ctd ${IMAGE} bash
# export CODENAME=$(docker exec build-ctd bash -c "lsb_release -c -s")
docker exec build-ctd apt update
# install deps
docker exec build-ctd apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo -y
docker exec build-ctd bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build-ctd bash -c "cd /root/ && wget https://dl.google.com/go/go1.13.8.linux-amd64.tar.gz && tar -C /usr/local -xzf  go1.13.8.linux-amd64.tar.gz"
# cloning repo inside container
docker exec build-ctd bash -c "cd /root && git clone https://github.com/eclipse-fog05/plugin-fdu-containerd -b ${BRANCH} --depth 1"

docker exec build-ctd bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/plugin-fdu-containerd && make && ldd plugin"
docker exec build-ctd bash -c "mkdir /root/build && cd /root && cp -r plugin-fdu-containerd build/fog05-plugin-fdu-containerd-${VERSION} && cd build/fog05-plugin-fdu-containerd-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-plugin-fdu-containerd-${VERSION}.tar.gz fog05-plugin-fdu-containerd-${VERSION}"
docker exec build-ctd bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ATO Labs\" && cd /root/build/fog05-plugin-fdu-containerd-${VERSION} && dh_make -f ../fog05-plugin-fdu-containerd-${VERSION}.tar.gz -s -y"
docker exec -e VERSION=${VERSION} build-ctd bash -c 'cd /root/build/fog05-plugin-fdu-containerd-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-fdu-containerd/lib/systemd/system/\n\t\$(MAKE) CTD_PLUGIN_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-containerd/etc/fos/plugins/plugin-fdu-containerd SYSTEMD_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-containerd/lib/systemd/system/ install">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
docker cp templates/changelog build-ctd:/root/build/fog05-plugin-fdu-containerd-${VERSION}/debian/changelog
docker cp templates/postinst build-ctd:/root/build/fog05-plugin-fdu-containerd-${VERSION}/debian/postinst
docker cp templates/control build-ctd:/root/build/fog05-plugin-fdu-containerd-${VERSION}/debian/control
docker cp templates/copyright build-ctd:/root/build/fog05-plugin-fdu-containerd-${VERSION}/debian/copyright

docker exec build-ctd bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/build/fog05-plugin-fdu-containerd-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l"
docker exec build-ctd bash -c "cd /root/build/ && dpkg -I fog05-plugin-fdu-containerd_${VERSION}-1_amd64.deb"

docker cp build-ctd:/root/build/fog05-plugin-fdu-containerd_${VERSION}-1_amd64.deb ../fog05-plugin-fdu-containerd_${VERSION}-1_amd64.deb

docker container rm --force build-ctd


set +x
echo $KEY  | base64 --decode > key
chmod 0600 key
scp -o StrictHostKeyChecking=no -i ./key ../fog05-plugin-fdu-containerd_${VERSION}-1_amd64.deb $USER@$SERVER:$DEPLOYDIR/fos/deb/bionic/amd64/
rm key
set -x