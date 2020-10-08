#!/bin/bash
set -e

if [[ -z "${VERSION}" ]]; then
  printf "Need to set the expected version of the packages!!\n"
  exit 1
fi


if [[ -z "${BRANCH}" ]]; then
  export BRANCH="master"
fi

if [[ -z "${IMAGE}" ]]; then
  export IMAGE="debian:10-slim"
fi

if [[ -z "${TAG}" ]]; then
  export TAG="latest"
fi

printf "Staring building of debian package ${PKG}-${VERSION} from branch ${BRANCH} using image ${IMAGE}\n"

case "$PKG" in
    fog05)
        cd fog05
        ./generate_deb.sh
        ;;
    fog05-plugin-os-linux)
        cd fog05-plugin-os-linux
        ./generate_deb.sh
        ;;
    fog05-plugin-net-linuxbridge)
        cd fog05-plugin-net-linuxbridge
        ./generate_deb.sh
        ;;
    fog05-plugin-fdu-native)
        cd fog05-plugin-fdu-native
        ./generate_deb.sh
        ;;
    fog05-plugin-fdu-ros2)
        cd fog05-plugin-fdu-ros2
        ./generate_deb.sh
        ;;
    fog05-plugin-fdu-kvm)
        cd fog05-plugin-fdu-kvm
        ./generate_deb.sh
        ;;
    fog05-plugin-fdu-lxd)
        cd fog05-plugin-fdu-lxd
        ./generate_deb.sh
    ;;
    fog05-plugin-fdu-containerd)
        cd fog05-plugin-fdu-containerd
        ./generate_deb.sh
    ;;
    fog05-python3-sdk)
        cd fog05-python3-sdk
        ./generate_deb.sh
    ;;
    fog05-python3-api)
        cd fog05-python3-api
        ./generate_deb.sh
    ;;
    fog05-force)
        cd fog05-force
        ./generate_image.sh
    ;;
    zenoh)
        cd zenoh
        ./generate_deb.sh
    ;;
    libzenoh)
        cd libzenoh
        ./generate_deb.sh
    ;;
    containerd)
        cd containerd
        ./generate_deb.sh
    ;;
    debian-ocaml)
    sg docker -c "docker build ./deb10-ocaml -f ./deb10-ocaml/Dockerfile -t fog05/debian-build:$TAG --no-cache" --oom-kill-disable
    ;;
    ubuntu-ocaml)
    sg docker -c "docker build ./ubu18-ocaml -f ./ubu18-ocaml/Dockerfile -t fog05/ubuntu-build:$TAG --no-cache" --oom-kill-disable
    ;;
    node-native)
    sg docker -c "docker build ./node_native -f ./node_native/Dockerfile -t fog05/node:native --no-cache" --oom-kill-disable
    ;;
    all)
    for d in */; do
        printf "Entering $d\n"
        cd $d
        if [-f "generate_deb.sh"]; then
             ./generate_deb.sh
        fi
        printf "Leaving $d\n"
        cd ..
    done
    mkdir debs
    mv *.deb debs/
    ;;
    *)
    printf "Unrecognized package name $PKG\n"
    exit 1
    ;;
esac

exit 0