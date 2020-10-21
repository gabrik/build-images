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
docker run -it -d --name build-fosctl ${IMAGE} bash
# export CODENAME=$(docker exec build-fosctl bash -c "lsb_release -c -s")
docker exec build-fosctl apt update
# install deps
docker exec build-fosctl apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo curl pkg-config libssl-dev -y
docker exec build-fosctl bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rust.sh && chmod +x /tmp/rust.sh"
docker exec build-fosctl bash -c "/tmp/rust.sh --default-toolchain nightly -y"
# cloning repo inside container
docker exec build-fosctl bash -c "cd /root && git clone https://github.com/eclipse-fog05/fog05/ -b ${BRANCH} --depth 1"

docker exec build-fosctl bash -c 'source ${HOME}/.cargo/env && cargo install cargo-deb && cd /root/fog05/src/utils/fosctl/ && make'

docker exec build-fosctl bash -c 'source ${HOME}/.cargo/env && cd /root/fog05/src/utils/fosctl/ && make deb && dpkg -I target/debian/fosctl_0.2.2~alpha1_arm64.deb'

docker cp "build-fosctl:/root/fog05/src/utils/fosctl/target/debian/fosctl_0.2.2~alpha1_arm64.deb" ../fog05-fosctl_${VERSION}-1_arm64.deb

docker container rm --force build-fosctl

if [ "$UPLOAD" = true ]; then
    set +x
    echo $KEY  | base64 --decode > key
    chmod 0600 key
    scp -o StrictHostKeyChecking=no -i ./key ../fog05-fosctl_${VERSION}-1_arm64.deb $USER@$SERVER:$DEPLOYDIR/fos/deb/bionic/arm64/fog05-fosctl-1_arm64.deb
    rm key
    set -x
fi