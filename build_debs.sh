#!/bin/bash
set -e

cd fog05-plugin-os-linux && ./generate_deb.sh && cd ..
cd fog05 && ./generate_deb.sh && cd ..
cd fog05-plugin-net-linuxbridge && ./generate_deb.sh && cd ..

mkdir debs
mv *.deb debs/

exit 0