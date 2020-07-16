#!/bin/bash

set -e

# UBUNTU="ubuntu:bionic"
# DEBIAN="debian:10-slim"

lxc launch images:${IMAGE} build
sleep 2
# install deps
lxc exec build -- apt install build-essential devscripts lintian dh-make git wget jq libev-dev libssl-dev m4 pkg-config rsync unzip cmake sudo -y
# install opam
lxc exec build -- bash -c "wget -O opam https://github.com/ocaml/opam/releases/download/2.0.6/opam-2.0.6-arm64-linux"
lxc exec build -- bash -c "install ./opam /usr/local/bin/opam"
lxc exec build -- bash -c "opam init --compiler=4.09.0 --disable-sandboxing -y"
# install other deps
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam install dune.1.11.4 atdgen.2.0.0 conf-libev ocp-ocamlres websocket-lwt.2.12 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add apero-core https://github.com/atolab/apero-core.git#0.4.6 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add dynload-sys https://github.com/atolab/apero-core.git#0.4.6 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add apero-net https://github.com/atolab/apero-net.git#0.4.6 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add apero-time https://github.com/atolab/apero-time.git#0.4.6 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add zenoh-proto https://github.com/atolab/zenoh.git#0.3.0 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add zenoh-tx-inet https://github.com/atolab/zenoh.git#0.3.0 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add zenoh-router https://github.com/atolab/zenoh.git#0.3.0 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add zenoh-ocaml https://github.com/atolab/zenoh.git#0.3.0 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add yaks-common https://github.com/atolab/yaks-common.git#0.3.0 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=3600 opam pin add yaks-ocaml https://github.com/atolab/yaks-ocaml.git#0.3.0 -y"
# clone repo
lxc exec build -- bash -c "cd /root && git clone https://github.com/atolab/zenoh -b 0.3.0 --depth 1"
lxc exec build -- bash -c "cd /root && git clone https://github.com/atolab/yaks -b 0.3.0 --depth 1"
# building a single zenoh+yaks
lxc exec build -- bash -c "cd /root && cp zenoh/zenoh-router-daemon.opam yaks/ && cp -r zenoh/src/zenoh-router-daemon yaks/src/"
lxc exec build -- bash -c "cd /root && sed -i 's/zenoh_proto/zenoh-proto/g' yaks/src/zenoh-router-daemon/dune"
lxc exec build -- bash -c "cd /root && sed -i 's/zenoh_tx_inet/zenoh-tx-inet/g' yaks/src/zenoh-router-daemon/dune"
lxc exec build -- bash -c "cd /root && sed -i 's/zenoh_router/zenoh-router/g' yaks/src/zenoh-router-daemon/dune"

lxc file push templates/Makefile build/root/yaks/Makefile
docker cp templates/zenoh.service build/root/yaks/zenoh.service

lxc exec build -- bash -c "eval \$(opam env) && cd /root/yaks && make"
lxc exec build -- bash -c "eval \$(opam env) && cd /root/yaks && make clean && rm -rf .git"

# build the debian package

lxc exec build -- bash -c "eval \$(opam env) && mkdir /root/build && cd /root && cp -r yaks build/zenoh-${VERSION} && cd build/zenoh-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf zenoh-${VERSION}.tar.gz zenoh-${VERSION}"
lxc exec build -- bash -c "eval \$(opam env) && cd /root/build/zenoh-${VERSION} && make clean"
lxc exec build -- bash -c "eval \$(opam env) && export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc.\" && cd /root/build/zenoh-${VERSION} && dh_make -f ../zenoh-${VERSION}.tar.gz -s -y"
lxc exec --env VERSION=${VERSION} build -- bash -c 'cd /root/build/zenoh-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/zenoh/lib/systemd/system/\n\t\$(MAKE) ZENOH_DIR=\$\$(pwd)/debian/zenoh/etc/zenoh SYSTEMD_DIR=\$\$(pwd)/debian/zenoh/lib/systemd/system/ install\n">> debian/rules'

sed -i "s/ZENOVERSION/${VERSION}/g" templates/changelog

lxc file push templates/changelog build/root/build/zenoh-${VERSION}/debian/changelog
lxc file push templates/postinst build/root/build/zenoh-${VERSION}/debian/postinst
lxc file push templates/control build/root/build/zenoh-${VERSION}/debian/control
lxc file push templates/copyright build/root/build/zenoh-${VERSION}/debian/copyright


lxc exec build -- bash -c "eval \$(opam env) && cd /root/build/zenoh-${VERSION} && debuild --preserve-envvar PATH --preserve-envvar OCAML_TOPLEVEL_PATH --preserve-envvar CAML_LD_LIBRARY_PATH --preserve-envvar OPAM_SWITCH_PREFIX -us -uc  && ls -l ../"
lxc exec build -- bash -c "cd /root/build/ && dpkg -I zenoh_${VERSION}-1_amd64.deb"

lxc file pull build/root/build/zenoh_${VERSION}-1_amd64.deb ../zenoh_${VERSION}-1_amd64.deb

lxc delete --force build