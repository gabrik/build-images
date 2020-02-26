#!/bin/bash

set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull ${IMAGE}
docker run -it -d --name build ${IMAGE} bash

# deps
docker exec build apt update
docker exec build apt install build-essential devscripts lintian dh-make git wget jq python3 python3-dev python3-pip unzip cmake sudo -y
docker exec build pip3 install pyangbind sphinx
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-python -b 0.3.0 --depth 1 && cd zenoh-python && python3 setup.py install"
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/yaks-python -b 0.3.0 --depth 1 && cd yaks-python && make install"
docker exec build bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/sdk-python -b v0.1.0 --depth 1 && cd sdk-python && make && make install"
docker exec build bash -c "cd /root/ && git clone https://github.com/eclipse-fog05/api-python -b v0.1.0 --depth 1 && cd api-python && make install"
# building deb file
docker exec build bash -c "cd /root/ && git clone https://github.com/gabrik/plugin-fdu-kvm -b ${BRANCH} --depth 1"
docker exec build bash -c "mkdir /root/build && cd /root && cp -r plugin-fdu-kvm build/fog05-plugin-fdu-kvm-${VERSION} && cd build/fog05-plugin-fdu-kvm-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-plugin-fdu-kvm-${VERSION}.tar.gz fog05-plugin-fdu-kvm-${VERSION}"
docker exec build bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc\" && cd /root/build/fog05-plugin-fdu-kvm-${VERSION} && dh_make -f ../fog05-plugin-fdu-kvm-${VERSION}.tar.gz -s -y"
docker exec -e VERSION=${VERSION} build bash -c 'cd /root/build/fog05-plugin-fdu-kvm-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05-plugin-fdu-kvm/lib/systemd/system/\n\t\$(MAKE) KVM_PLUGIN_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-kvm/etc/fos/plugins/plugin-fdu-kvm SYSTEMD_DIR=\$\$(pwd)/debian/fog05-plugin-fdu-kvm/lib/systemd/system/ install">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
docker cp templates/changelog build:/root/build/fog05-plugin-fdu-kvm-${VERSION}/debian/changelog
docker cp templates/postinst build:/root/build/fog05-plugin-fdu-kvm-${VERSION}/debian/postinst
docker cp templates/postrm build:/root/build/fog05-plugin-fdu-kvm-${VERSION}/debian/postrm
docker cp templates/control build:/root/build/fog05-plugin-fdu-kvm-${VERSION}/debian/control
docker cp templates/copyright build:/root/build/fog05-plugin-fdu-kvm-${VERSION}/debian/copyright

docker exec build bash -c "cd /root/build/fog05-plugin-fdu-kvm-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
docker exec build bash -c "cd /root/build/ && dpkg -I fog05-plugin-fdu-kvm_${VERSION}-1_amd64.deb"
docker cp build:/root/build/fog05-plugin-fdu-kvm_${VERSION}-1_amd64.deb ../fog05-plugin-fdu-kvm_${VERSION}-1_amd64_${IMAGE}.deb

docker container rm --force build