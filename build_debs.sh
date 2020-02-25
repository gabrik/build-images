#!/bin/bash
set -e

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
    all)
    cd fog05 && ./generate_deb.sh && cd ..
    cd fog05-plugin-os-linux && ./generate_deb.sh && cd ..
    cd fog05-plugin-net-linuxbridge && ./generate_deb.sh && cd ..
    cd fog05-plugin-fdu-native && ./generate_deb.sh && cd ..
    cd fog05-plugin-fdu-kvm && ./generate_deb.sh && cd ..
    cd fog05-plugin-fdu-lxd && ./generate_deb.sh && cd ..
    cd fog05-plugin-fdu-containerd && ./generate_deb.sh && cd ..
    mkdir debs
    mv *.deb debs/
    ;;
    *)
    ;;
esac

exit 0