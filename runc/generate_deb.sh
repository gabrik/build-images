#!/bin/bash

set -e

docker pull ${IMAGE}
docker run -it -d --name build-runc ${IMAGE} bash

docker exec build-runc apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo pkg-config libseccomp-dev -y
docker exec build-runc bash -c "cd /root/ && wget https://dl.google.com/go/go1.13.8.linux-arm64.tar.gz && tar -C /usr/local -xzf  go1.13.8.linux-arm64.tar.gz"

# clone repos
docker exec build-runc bash -c "cd /root && git clone https://github.com/opencontainers/runc -b ${BRANCH} --depth 1"


# build
docker exec  build-runc bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/runc && make"

docker exec  build-runc bash -c "cd /root/runc && make clean && rm -rf .git"

# building a debian package
docker exec build-runc bash -c "mkdir /root/build && cd /root && cp -r runc build/runc-${VERSION} && cd build/runc-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf runc-${VERSION}.tar.gz runc-${VERSION}"
docker exec build-runc bash -c "cd /root/build/runc-${VERSION} && make clean"
docker exec build-runc bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc.\" && cd /root/build/runc-${VERSION} && dh_make -f ../runc-${VERSION}.tar.gz -s -y"
docker exec -e VERSION=${VERSION} build-runc bash -c 'cd /root/build/runc-${VERSION} && printf "override_dh_auto_install:\n\t\$(MAKE) DESTDIR=\$\$(pwd)/debian/runc/ install\n">> debian/rules'



docker exec build-runc bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/build/runc-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
docker exec build-runc bash -c "cd /root/build/ && dpkg -I runc_${VERSION}-1_arm64.deb"


docker cp build-runc:/root/build/runc_${VERSION}-1_arm64.deb ../runc_${VERSION}-1_arm64.deb

docker container rm --force build-runc