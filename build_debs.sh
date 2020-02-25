#!/bin/bash
set -e

cd fog05-plugin-os-linux && ./generate_deb.sh
cd fog05 && ./generate_deb.sh

mkdir debs
mv *.deb debs/

exit 0