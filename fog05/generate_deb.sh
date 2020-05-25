#!/bin/bash

set -e

# UBUNTU="ubuntu:bionic"
# DEBIAN="debian:10-slim"

docker pull ${IMAGE}
docker run -it -d --name build-agent ${IMAGE} bash

# install deps
docker exec build-agent apt update
docker exec build-agent apt install build-essential devscripts lintian dh-make git wget jq libev-dev libssl-dev m4 pkg-config rsync unzip cmake sudo -y
# install opam
docker exec build-agent wget -O opam https://github.com/ocaml/opam/releases/download/2.0.6/opam-2.0.6-x86_64-linux
docker exec build-agent install ./opam /usr/local/bin/opam
docker exec build-agent opam init --compiler=4.09.0 --disable-sandboxing
# install other deps
docker exec build-agent bash -c "eval \$(opam env) && opam install dune.1.11.4 atdgen.2.0.0 conf-libev ocp-ocamlres websocket-lwt.2.12 -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add apero-core https://github.com/atolab/apero-core.git#0.4.6 -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add dynload-sys https://github.com/atolab/apero-core.git#0.4.6 -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add apero-net https://github.com/atolab/apero-net.git#0.4.6 -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add apero-time https://github.com/atolab/apero-time.git#0.4.6 -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add zenoh-proto https://github.com/atolab/zenoh.git#0.3.0 -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add zenoh-ocaml https://github.com/atolab/zenoh.git#0.3.0 -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add yaks-common https://github.com/atolab/yaks-common.git#0.3.0 -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add yaks-ocaml https://github.com/atolab/yaks-ocaml.git#0.3.0 -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add fos-sdk https://github.com/eclipse-fog05/sdk-ocaml.git#${BRANCH} -y"
docker exec build-agent bash -c "eval \$(opam env) && opam pin add fos-fim-api https://github.com/eclipse-fog05/api-ocaml.git#${BRANCH}  -y"
# clone repo
docker exec build-agent bash -c "cd /root && git clone https://github.com/eclipse-fog05/agent -b ${BRANCH} --depth 1"
# building a debian package
docker exec build-agent bash -c "eval \$(opam env) && mkdir /root/build && cd /root && cp -r agent build/fog05-${VERSION} && cd build/fog05-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf fog05-${VERSION}.tar.gz fog05-${VERSION}"
docker exec build-agent bash -c "eval \$(opam env) && cd /root/build/fog05-${VERSION} && make clean"
docker exec build-agent bash -c "eval \$(opam env) && export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc.\" && cd /root/build/fog05-${VERSION} && dh_make -f ../fog05-${VERSION}.tar.gz -s -y"
docker exec -e VERSION=${VERSION} build-agent bash -c 'cd /root/build/fog05-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05/lib/systemd/system/\n\t\$(MAKE) FOS_DIR=\$\$(pwd)/debian/fog05/etc/fos SYSTEMD_DIR=\$\$(pwd)/debian/fog05/lib/systemd/system/ install\n">> debian/rules'

sed -i "s/FOSVERSION/${VERSION}/g" templates/changelog
docker cp templates/changelog build-agent:/root/build/fog05-${VERSION}/debian/changelog
docker cp templates/postinst build-agent:/root/build/fog05-${VERSION}/debian/postinst
docker cp templates/postrm build-agent:/root/build/fog05-${VERSION}/debian/postrm
docker cp templates/control build-agent:/root/build/fog05-${VERSION}/debian/control
docker cp templates/copyright build-agent:/root/build/fog05-${VERSION}/debian/copyright

docker exec build-agent bash -c "eval \$(opam env) && cd /root/build/fog05-${VERSION} && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
docker exec build-agent bash -c "cd /root/build/ && dpkg -I fog05_${VERSION}-1_amd64.deb"



docker cp build-agent:/root/build/fog05_${VERSION}-1_amd64.deb ../fog05_${VERSION}-1_amd64_${IMAGE}.deb

docker exec build-agent bash -c "eval \$(opam env) && cd /root/agent && make && cd .. && tar -czvf fog05-${VERSION}.tar.gz agent"
docker cp build-agent:/root/fog05-${VERSION}.tar.gz ../fog05-${VERSION}.tar.gz


docker container rm --force build-agent