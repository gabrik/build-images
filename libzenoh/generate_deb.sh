set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull ${IMAGE}
docker run -it -d --name build ${IMAGE} bash
docker exec build apt update
# install deps
docker exec build apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo -y
# clone repos
docker exec build bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1"


docker cp templates/CMakeLists.txt build:/root/zenoh-c/CMakeLists.txt

docker exec build bash -c "cd /root/zenoh-c && make && cd build && cpack"
docker exec build bash -c "cd /root/zenoh-c/build/ && dpkg -I libzenoh-0.3.0-Linux.deb"


docker cp build:/root/zenoh-c/build/libzenoh-0.3.0-Linux.deb ../libzenoh-0.3.0-Linux.deb

docker container rm --force build