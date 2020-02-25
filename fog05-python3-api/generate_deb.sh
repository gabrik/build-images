#!/bin/bash

set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull $DEBIAN
docker run -it -d --name build $DEBIAN bash
# deps
docker exec build apt update
docker exec build apt install build-essential devscripts lintian dh-make git python3 python3-dev python3-pip unzip sudo python3-all python-all cmake wget -y
docker exec build pip3 install pyangbind sphinx stdeb
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1 && cd zenoh-c && make && make install"
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-python -b 0.3.0 --depth 1 && cd zenoh-python && python3 setup.py install"
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/yaks-python -b 0.3.0 --depth 1 && cd yaks-python && make install"
docker exec build bash -c "cd /root/ && git clone https://github.com/gabrik/api-python fog05-api-0.1"
# build package
docker exec build bash -c "cd /root/fog05-api-0.1 && make"
#build deb
docker exec build bash -c "cd /root && mkdir build && tar -czvf build/fog05-api-0.1.tar.gz fog05-api-0.1"
docker exec build bash -c "cd /root/build && py2dsc fog05-api-0.1.tar.gz"
docker exec build bash -c "cd /root/build/deb_dist/fog05-api-0.1.0 && dpkg-buildpackage -rfakeroot -uc -us"
docker exec build bash -c "cd /root/build/deb_dist/ && dpkg -I python3-fog05_0.1.0-1_all.deb"
docker cp build:/root/build/deb_dist/python3-fog05_0.1.0-1_all.deb ../python3-fog05_0.1.0-1_all_debian_buster.deb

docker container rm --force build