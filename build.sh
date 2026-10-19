#!/bin/bash
# Makes the two zips from package/ (rebuild package/EtherPets/EtherPets.pck first with pack.gd, see the README):
#   out/EtherPets-mod.zip         the EtherPets folder to drop into GDWeave/mods
#   out/EtherPets-<version>.zip   the Thunderstore upload
set -e
cd "$(dirname "$0")"
mkdir -p out
V=$(python3 -c "import json;print(json.load(open('thunderstore/manifest.json'))['version_number'])")
rm -f out/EtherPets-mod.zip out/EtherPets-$V.zip
(cd package && zip -qr ../out/EtherPets-mod.zip EtherPets)
T=$(mktemp -d)
cp thunderstore/manifest.json thunderstore/README.md thunderstore/CHANGELOG.md thunderstore/icon.png $T/
cp LICENSE $T/
mkdir -p $T/GDWeave/mods/EtherPets
cp package/EtherPets/manifest.json package/EtherPets/EtherPets.pck $T/GDWeave/mods/EtherPets/
(cd $T && zip -qr - .) > out/EtherPets-$V.zip
rm -rf $T
echo "out/EtherPets-mod.zip"
echo "out/EtherPets-$V.zip"
