#!/bin/bash

set -e


git clone https://github.com/docker/containerd-packaging

cd containerd-packaging

./scripts/new-deb-release ${VERSION}

cp ../templates/containerd.service ./common/containerd.service

make REF=${BRANCH} BUILD_IMAGE=docker.io/library/${IMAGE}

dpkg -I build/ubuntu/bionic/arm64/containerd.io_${VERSION}-1_amd64.deb

cp  build/ubuntu/bionic/arm64/containerd.io_${VERSION}-1_amd64.deb ../

rm -rf containerd-packaging