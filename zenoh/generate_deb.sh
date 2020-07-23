#!/bin/bash

set -e

docker pull ${IMAGE}
docker run -it -d --name build-z ${IMAGE} bash

docker exec build-z bash -c "eval \$(opam env) && opam pin add zenoh-tx-inet https://github.com/atolab/zenoh.git#0.3.0 -y"
docker exec build-z bash -c "eval \$(opam env) && opam pin add zenoh-router https://github.com/atolab/zenoh.git#0.3.0 -y"


# clone repos
docker exec build-z bash -c "cd /root && git clone https://github.com/atolab/zenoh -b ${BRANCH} --depth 1"
docker exec build-z bash -c "cd /root && git clone https://github.com/atolab/yaks -b ${BRANCH} --depth 1"
# preparing sole zenohd+yaks
docker exec build-z bash -c "cd /root && cp zenoh/zenoh-router-daemon.opam yaks/ && cp -r zenoh/src/zenoh-router-daemon yaks/src/"
docker exec build-z bash -c "cd /root && sed -i 's/zenoh_proto/zenoh-proto/g' yaks/src/zenoh-router-daemon/dune"
docker exec build-z bash -c "cd /root && sed -i 's/zenoh_tx_inet/zenoh-tx-inet/g' yaks/src/zenoh-router-daemon/dune"
docker exec build-z bash -c "cd /root && sed -i 's/zenoh_router/zenoh-router/g' yaks/src/zenoh-router-daemon/dune"
docker cp templates/Makefile build-z:/root/yaks/Makefile
docker cp templates/zenoh.service build-z:/root/yaks/zenoh.service

docker exec build-z bash -c "cd /root/yaks && rm -rf yaks-be-influxdb.opam yaks-be-sql.opam rm -rf src/yaks-be/yaks-be-sql/ src/yaks-be/yaks-be-influxdb/"

# build
docker exec  build-z bash -c "eval \$(opam env) && cd /root/yaks && make"

docker exec  build-z bash -c "eval \$(opam env) && cd /root/yaks && make clean && rm -rf .git"

# building a debian package
docker exec build-z bash -c "eval \$(opam env) && mkdir /root/build && cd /root && cp -r yaks build/zenoh-${VERSION} && cd build/zenoh-${VERSION} && rm -rf .git && make clean && cd .. && tar -czvf zenoh-${VERSION}.tar.gz zenoh-${VERSION}"
docker exec build-z bash -c "eval \$(opam env) && cd /root/build/zenoh-${VERSION} && make clean"
docker exec build-z bash -c "eval \$(opam env) && export DEBEMAIL=\"info@adlink-labs.tech\" && export DEBFULLNAME=\"ADLINK Technology Inc.\" && cd /root/build/zenoh-${VERSION} && dh_make -f ../zenoh-${VERSION}.tar.gz -s -y"
docker exec -e VERSION=${VERSION} build-z bash -c 'cd /root/build/zenoh-${VERSION} && printf "override_dh_auto_install:\n\tmkdir -p \$\$(pwd)/debian/zenoh/lib/systemd/system/\n\t\$(MAKE) ZENOH_DIR=\$\$(pwd)/debian/zenoh/etc/zenoh SYSTEMD_DIR=\$\$(pwd)/debian/zenoh/lib/systemd/system/ install\n">> debian/rules'

sed -i "s/ZENOVERSION/${VERSION}/g" templates/changelog
docker cp templates/changelog build-z:/root/build/zenoh-${VERSION}/debian/changelog
docker cp templates/postinst build-z:/root/build/zenoh-${VERSION}/debian/postinst
# docker cp templates/postrm build-z:/root/build/zenoh-${VERSION}/debian/postrm
docker cp templates/control build-z:/root/build/zenoh-${VERSION}/debian/control
docker cp templates/copyright build-z:/root/build/zenoh-${VERSION}/debian/copyright

docker exec build-z bash -c "eval \$(opam env) && cd /root/build/zenoh-${VERSION} && debuild --preserve-envvar PATH --preserve-envvar OCAML_TOPLEVEL_PATH --preserve-envvar CAML_LD_LIBRARY_PATH --preserve-envvar OPAM_SWITCH_PREFIX -us -uc  && ls -l ../"
docker exec build-z bash -c "cd /root/build/ && dpkg -I zenoh_${VERSION}-1_amd64.deb"


docker cp build-z:/root/build/zenoh_${VERSION}-1_amd64.deb ../zenoh_${VERSION}-1_amd64.deb

docker exec build-z bash -c "eval \$(opam env) && cd /root/yaks && make && cd .. && tar -czvf zenoh-${VERSION}.tar.gz yaks"
docker cp build-z:/root/zenoh-${VERSION}.tar.gz ../zenoh-${VERSION}.tar.gz


docker container rm --force build-z



set +x
echo $KEY  | base64 --decode > key
chmod 0600 key
scp -o StrictHostKeyChecking=no -i ./key ../zenoh_${VERSION}-1_amd64.deb $USER@$SERVER:~
rm key
set -x