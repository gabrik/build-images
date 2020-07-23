set -e

UBUNTU="ubuntu:bionic"
DEBIAN="debian:10-slim"

docker pull ${IMAGE}
docker run -it -d --name build-lz ${IMAGE} bash
export CODENAME=$(docker exec build-lz bash -c "lsb_release -c -s")
docker exec build-lz apt update
# install deps
docker exec build-lz apt install build-essential devscripts lintian dh-make git wget jq unzip cmake sudo -y
# clone repos
docker exec build-lz bash -c "cd /root/ && git clone https://github.com/atolab/zenoh-c -b 0.3.0 --depth 1"


docker cp templates/CMakeLists.txt build-lz:/root/zenoh-c/CMakeLists.txt

docker exec build-lz bash -c "cd /root/zenoh-c && make && cd build && cpack"
docker exec build-lz bash -c "cd /root/zenoh-c/build/ && dpkg -I libzenoh-0.3.0-Linux.deb"


docker cp build-lz:/root/zenoh-c/build/libzenoh-0.3.0-Linux.deb ../libzenoh-0.3.0-Linux.deb

docker container rm --force build-lz


set +x
echo $KEY  | base64 --decode > key
chmod 0600 key
scp -o StrictHostKeyChecking=no -i ./key ../libzenoh-0.3.0-Linux.deb $USER@$SERVER:~/fos/deb/bionic/amd64/libzenoh-0.3.0-amd64.deb
rm key
set -x