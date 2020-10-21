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

docker exec build-force bash -c "export PATH=\$PATH:/usr/local/go/bin && cd /root/fog05/src/force && make"


docker cp build-force:/root/fog05/src/force/force ./force

docker container rm --force build-force

sg docker -c "docker build ./ -f ./Dockerfile.arm64 -t fog05/force --no-cache" --oom-kill-disable