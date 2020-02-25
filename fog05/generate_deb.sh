#!/bin/bash

set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull $DEBIAN
docker run -it -d --name build $DEBIAN bash

# install deps
docker exec build apt update
docker exec build apt install build-essential devscripts lintian dh-make git wget jq libev-dev libssl-dev python3 python3-dev python3-pip m4 pkg-config rsync unzip cmake sudo -y
docker exec build pip3 install pyangbind
# install opam
docker exec build wget -O opam https://github.com/ocaml/opam/releases/download/2.0.6/opam-2.0.6-x86_64-linux
docker exec build install ./opam /usr/local/bin/opam
docker exec build opam init --disable-sandboxing
# install other deps
docker exec build bash -c "eval \$(opam env) && opam install dune.1.11.4 atdgen.2.0.0 conf-libev ocp-ocamlres -y"
docker exec build bash -c "eval \$(opam env) && opam pin add apero-core https://github.com/atolab/apero-core.git#0.4.6 -y"
docker exec build bash -c "eval \$(opam env) && opam pin add dynload-sys https://github.com/atolab/apero-core.git#0.4.6 -y"
docker exec build bash -c "eval \$(opam env) && opam pin add apero-net https://github.com/atolab/apero-net.git#0.4.6 -y"
docker exec build bash -c "eval \$(opam env) && opam pin add apero-time https://github.com/atolab/apero-time.git#0.4.6 -y"
docker exec build bash -c "eval \$(opam env) && opam pin add zenoh-proto https://github.com/atolab/zenoh.git#0.3.0 -y"
docker exec build bash -c "eval \$(opam env) && opam pin add zenoh-ocaml https://github.com/atolab/zenoh.git#0.3.0 -y"
docker exec build bash -c "eval \$(opam env) && opam pin add yaks-common https://github.com/atolab/yaks-common.git#0.3.0 -y"
docker exec build bash -c "eval \$(opam env) && opam pin add yaks-ocaml https://github.com/atolab/yaks-ocaml.git#0.3.0 -y"
docker exec build bash -c "eval \$(opam env) && opam pin add fos-sdk https://github.com/eclipse-fog05/sdk-ocaml.git#0.1 -y"
docker exec build bash -c "eval \$(opam env) && opam pin add fos-fim-api https://github.com/eclipse-fog05/api-ocaml.git#0.1  -y"
# clone repo
docker exec build bash -c "cd /root && git clone https://github.com/eclipse-fog05/agent"
# building a debian package
docker exec build bash -c "eval \$(opam env) && mkdir /root/build && cd /root && cp -r agent build/fog05-0.1 && cd build/fog05-0.1 && rm -rf .git && make clean && cd .. && tar -czvf fog05-0.1.tar.gz fog05-0.1"
docker exec build bash -c "eval \$(opam env) && cd /root/build/fog05-0.1 && make clean"
docker exec build bash -c "eval \$(opam env) && export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc.\" && cd /root/build/fog05-0.1 && dh_make -f ../fog05-0.1.tar.gz -s -y"
docker exec build bash -c 'cd /root/build/fog05-0.1 && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/fog05/lib/systemd/system/\n\t\$(MAKE) FOS_DIR=\$\$(pwd)/debian/fog05/etc/fos SYSTEMD_DIR=\$\$(pwd)/debian/fog05/lib/systemd/system/ install\n">> debian/rules'

docker cp templates/changelog build:/root/build/fog05-0.1/debian/changelog
docker cp templates/postinst build:/root/build/fog05-0.1/debian/postinst
docker cp templates/postrm build:/root/build/fog05-0.1/debian/postrm
docker cp templates/control build:/root/build/fog05-0.1/debian/control
docker cp templates/copyright build:/root/build/fog05-0.1/debian/copyright

docker exec build bash -c "eval \$(opam env) && cd /root/build/fog05-0.1 && debuild --preserve-envvar PATH -us -uc  && ls -l ../"
docker exec build bash -c "cd /root/build/ && dpkg -I fog05_0.1-1_amd64.deb"


docker cp build:/root/build/fog05_0.1-1_amd64.deb ../fog05_0.1-1_amd64_debian_buster.deb

docker container rm --force build