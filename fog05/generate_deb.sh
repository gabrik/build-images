#!/bin/bash

set -e

# UBUNTU="ubuntu:bionic"
# DEBIAN="debian:10-slim"

docker pull ${IMAGE}
docker run -it -d --name build-agent ${IMAGE} bash

# install deps
docker exec build-agent apt update
docker exec build-agent apt install build-essential devscripts debhelper pkg-config libssl-dev curl -y
# install rust nightly
docker exec build-agent curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rust.sh
docker exec build-agent chmod +x /tmp/rust.sh
docker exec build-agent /tmp/rust.sh --default-toolchain nightly -y
# install cargo deb
docker exec build-agent bash -c 'source $HOME/.cargo/env && cargo install cargo-deb'

# clone repo
docker exec -e BRANCH=$BRANCH build-agent bash -c 'source $HOME/.cargo/env && cd /root && git clone https://github.com/eclipse-fog05/fog05 -b $BRANCH'
# build
docker exec build-agent bash -c 'source $HOME/.cargo/env && cd /root/fog05/ && cargo check'
docker exec build-agent bash -c 'source $HOME/.cargo/env && cd /root/fog05/ && cargo build --release'

# debian packages
docker exec build-agent bash -c 'source $HOME/.cargo/env && cd /root/fog05/ && cargo deb -p fog05-agent --no-build'
docker exec build-agent bash -c 'source $HOME/.cargo/env && cd /root/fog05/ && cargo deb -p fog05-fosctl --no-build'

C_A_VERSION=$(docker exec build-agent bash -c "cd /root/fog05/ && cat fog05-agent/Cargo.toml | grep version | head -n1 | sed 's/[^\"]*\"\([^\"]*\)\".*/\1/' | tr '-' '~'")
C_C_VERSION=$(docker exec build-agent bash -c "cd /root/fog05/ && cat fog05-fosctl/Cargo.toml | grep version | head -n1 | sed 's/[^\"]*\"\([^\"]*\)\".*/\1/' | tr '-' '~'")

# check packages
docker exec -e VERSION=C_A_VERSION build-agent bash -c 'cd /root/fog05/ && dpkg -I ./target/release/debian/fog05-agent_$VERSION_amd64.deb'
docker exec -e VERSION=C_C_VERSION build-agent bash -c 'cd /root/fog05/ && dpkg -I ./target/release/debian/fog05-fosctl_$VERSION_amd64.deb'



# docker cp build-agent:/root/build/fog05_${VERSION}-1_amd64.deb ../fog05_${VERSION}-1_amd64_${IMAGE}.deb

# docker exec build-agent bash -c "eval \$(opam env) && cd /root/agent && make && cd .. && tar -czvf fog05-${VERSION}.tar.gz agent"
# docker cp build-agent:/root/fog05-${VERSION}.tar.gz ../fog05-${VERSION}.tar.gz


docker container rm --force build-agent
