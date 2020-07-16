#!/bin/bash

set -e

# UBUNTU="ubuntu:bionic"
# DEBIAN="debian:10-slim"

lxc launch images:${IMAGE} build
sleep 2
# install deps
lxc exec build -- apt update
lxc exec build -- apt install build-essential devscripts lintian dh-make git wget jq libev-dev libssl-dev m4 pkg-config rsync unzip cmake sudo -y
# install opam
lxc exec build -- bash -c "wget -O opam https://github.com/ocaml/opam/releases/download/2.0.6/opam-2.0.6-arm64-linux"
lxc exec build -- bash -c "install ./opam /usr/local/bin/opam"
lxc exec build -- bash -c "opam init --compiler=4.09.0 --disable-sandboxing -y"
# install other deps
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam install dune.1.11.4 atdgen.2.0.0 conf-libev ocp-ocamlres websocket-lwt.2.12 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add apero-core https://github.com/atolab/apero-core.git#0.4.6 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add dynload-sys https://github.com/atolab/apero-core.git#0.4.6 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add apero-net https://github.com/atolab/apero-net.git#0.4.6 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add apero-time https://github.com/atolab/apero-time.git#0.4.6 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add zenoh-proto https://github.com/atolab/zenoh.git#0.3.0 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add zenoh-ocaml https://github.com/atolab/zenoh.git#0.3.0 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add yaks-common https://github.com/atolab/yaks-common.git#0.3.0 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add yaks-ocaml https://github.com/atolab/yaks-ocaml.git#0.3.0 -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add fos-sdk https://github.com/eclipse-fog05/sdk-ocaml.git#master -y"
lxc exec build -- bash -c "eval \$(opam env) && OPAMSOLVERTIMEOUT=240 opam pin add fos-fim-api https://github.com/eclipse-fog05/api-ocaml.git#master  -y"
# clone repo
lxc exec build -- bash -c "cd /root && git clone https://github.com/eclipse-fog05/agent -b ${BRANCH} --depth 1"
# building a debian package
lxc exec build -- bash -c "eval \$(opam env) && mkdir /root/build && cd /root && cp -r agent build/fog05-${VERSION} && cd build/fog05-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-${VERSION}.tar.gz fog05-${VERSION}"
lxc exec build -- bash -c "eval \$(opam env) && cd /root/build/fog05-${VERSION} && make clean"
lxc exec build -- bash -c "eval \$(opam env) && export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc.\" && cd /root/build/fog05-${VERSION} && dh_make -f ../fog05-${VERSION}.tar.gz -s -y"
lxc exec --env VERSION=${VERSION} build -- bash -c 'cd /root/build/fog05-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05/lib/systemd/system/\n\t\$(MAKE) FOS_DIR=\$\$(pwd)/debian/fog05/etc/fos SYSTEMD_DIR=\$\$(pwd)/debian/fog05/lib/systemd/system/ install\n">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
lxc file push templates/changelog build/root/build/fog05-${VERSION}/debian/changelog
lxc file push templates/postinst build/root/build/fog05-${VERSION}/debian/postinst
lxc file push templates/postrm build/root/build/fog05-${VERSION}/debian/postrm
lxc file push templates/control build/root/build/fog05-${VERSION}/debian/control
lxc file push templates/copyright build/root/build/fog05-${VERSION}/debian/copyright

lxc exec build -- bash -c "eval \$(opam env) && cd /root/build/fog05-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
lxc exec build -- bash -c "cd /root/build/ && dpkg -I fog05_${VERSION}-1_amd64.deb"


lxc file pull build/root/build/fog05_${VERSION}-1_amd64.deb ../fog05_${VERSION}-1_amd64_${IMAGE}.deb

lxc delete --force build