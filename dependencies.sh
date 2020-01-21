#!/bin/bash

DEPS="fog05_deps"
DIRECT="direct"
INDIRECT="indirect"

WD=$(pwd)

mkdir $DEPS
cd $DEPS
mkdir $DIRECT
mkdir $INDIRECT

cd $DIRECT
git clone https://github.com/ocaml/ocaml-re -b 1.9.0 --depth 1
git clone https://github.com/dbuenzli/cmdliner -b v1.0.4 --depth 1
git clone https://github.com/ocaml-community/yojson -b 1.7.0 --depth 1
git clone https://github.com/dbuenzli/logs
git clone https://github.com/ocsigen/lwt -b 5.1.1 --depth 1
git clone https://github.com/atolab/apero-core -b 0.4.5 --depth 1
git clone https://github.com/atolab/apero-net -b 0.4.5 --depth 1
git clone https://github.com/atolab/yaks-ocaml && cd yaks-ocaml && git checkout d076645 && cd ..
git clone https://github.com/atolab/yaks-common && cd yaks-common && git checkout 5d2e70d && cd ..
git clone https://github.com/atolab/yaks-go -b v0.3.0 --depth 1
git clone https://github.com/sirupsen/logrus -b v1.4.2 --depth 1
git clone https://github.com/google/uuid -b v1.1.1 --depth 1
git clone https://github.com/atolab/yaks-python && cd yaks-python && git checkout 50c9fc7 && cd ..
git clone https://github.com/Julian/jsonschema -b v2.6.0 --depth 1
git clone https://github.com/gabrik/mvar-python
git clone https://github.com/robshakir/pyangbind -b 0.8.1 --depth 1
git clone https://github.com/giampaolo/psutil -b release-5.6.7 --depth 1
git clone https://github.com/al45tair/netifaces -b release 0_10_4 --depth 1
git clone https://github.com/pallets/jinja -b 2.10 --depth 1
git clone https://github.com/lxc/pylxd -b 2.2.10 --depth 1
git clone https://libvirt.org/git/libvirt-python.git -b v4.0.0  --depth 1
git clone http://github.com/opencontainers/runtime-spec -b 1.0.1 --depth 1
git clone https://github.com/fatih/structs -b 1.1.0 --depth 1
git clone https://github.com/containerd/containerd -b v1.3.1 --depth 1

for d in */; do
    cd $d
    rm -rf .git .gitignore .git* .travis*
    cd ..
done

cd ..
cd $INDIRECT
wget http://dist.schmorp.de/libev/Attic/libev-4.22.tar.gz && tar -xzvf libev-4.22.tar.gz && rm -rf libev-4.22.tar.gz
git clone https://github.com/openssl/openssl -b OpenSSL_1_1_1 --depth 1
git clone https://libvirt.org/git/libvirt.git -b v4.0.0 --depth 1
git clone https://git.qemu.org/git/qemu.git -b v2.11.1 --depth 1
git clone https://github.com/lxc/lxd -b lxd-3.18 --depth 1
git clone https://github.com/containerd/containerd -b v1.3.1 --depth 1
git clone http://github.com/atolab/zenoh-c && cd zenoh-c && git checkout 1e20bb6 && cd ..
git clone http://github.com/atolab/zenoh && cd zenoh && git checkout 46d4378 && cd ..
git clone http://github.com/atolab/yaks && cd zenoh && git checkout 0.3.0 && cd ..

for d in */; do
    cd $d
    rm -rf .git .gitignore .git* .travis*
    cd ..
done

cd $WD
tar -zcvf fog05_deps.tar.gz $DEPS