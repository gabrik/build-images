#!/bin/bash

set -e


git clone https://github.com/docker/containerd-packaging

cd containerd-packaging

./scripts/new-deb-release ${VERSION}

cp ../templates/containerd.service ./common/containerd.service

make REF=${BRANCH} BUILD_IMAGE=docker.io/library/${IMAGE}

dpkg -I build/ubuntu/bionic/arm64/containerd.io_${VERSION}-1_arm64.deb


# docker pull ${IMAGE}
# docker run -it -d --name build-containerd ${IMAGE} bash

# docker exec build-containerd apt update
# docker exec build-containerd apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo pkg-config libseccomp-dev btrfs-tools -y
# docker exec build-containerd bash -c "cd /root/ && wget https://dl.google.com/go/go1.13.8.linux-amd64.tar.gz && tar -C /usr/local -xzf  go1.13.8.linux-amd64.tar.gz"

# # clone repos
# docker exec build-containerd bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root && go get github.com/containerd/containerd && cd go/src/github.com/containerd/containerd && git checkout v1.3.2"


# # build
# docker exec  build-containerd bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/go/src/github.com/containerd/containerd && make"

# docker exec  build-containerd bash -c "cd /root/go/src/github.com/containerd/containerd && make clean"

# # building a debian package
# docker exec build-containerd bash -c "mkdir /root/build && cd /root && cp -r go/src/github.com/containerd/containerd build/containerd-1.3.2 && cd build/containerd-1.3.2 && make clean && cd .. && tar -czvf containerd-1.3.2.tar.gz containerd-1.3.2"
# docker exec build-containerd bash -c "cd /root/build/containerd-1.3.2 && make clean"
# docker exec build-containerd bash -c "export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc.\" && cd /root/build/containerd-1.3.2 && dh_make -f ../containerd-1.3.2.tar.gz -s -y"
# docker exec build-containerd bash -c 'cd /root/build/containerd-1.3.2 && printf "override_dh_auto_install:\n\t\$(MAKE) DESTDIR=\$\$(pwd)/debian/containerd/ install\n">> debian/rules'



# docker exec build-containerd bash -c "export GOPATH=\"\$HOME/go\" && export PATH=\$PATH:/usr/local/go/bin && cd /root/build/containerd-1.3.2 && debuild --preserve-envvar PATH --preserve-envvar GOPATH -us -uc  && ls -l ../"
# docker exec build-containerd bash -c "cd /root/build/ && dpkg -I containerd_1.3.2-1_amd64.deb"


# docker cp build-containerd:/root/build/containerd_1.3.2-1_amd64.deb ../containerd_1.3.2-1_amd64.deb

# docker container rm --force build-containerd