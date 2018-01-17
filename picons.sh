#!/bin/bash -e

echo "Setting up channel icons for Kodi VDR VNSI plugin ..."

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

PICONS_SOURCE_DIR=$SETUPROOT/source
PICONS_OUT_DIR=$SETUPROOT/vnsi

# Get repo
if [ ! -d "$PICONS_SOURCE_DIR" ]
then
   git clone https://github.com/picons/picons-source.git $PICONS_SOURCE_DIR
fi

pushd $PICONS_SOURCE_DIR

git reset --hard HEAD
git pull
rm -rf build-input/* build-output/*
echo '256x256;226x226;light;transparent' > build-input/backgrounds.conf
cp -fv /var/lib/vdr/channels.conf build-input/
./1-build-servicelist.sh srp
./2-build-picons.sh srp
rm -rf $PICONS_OUT_DIR
mkdir -p $PICONS_OUT_DIR
tar xvf build-output/binaries-srp/*.symlink.tar.xz --directory $PICONS_OUT_DIR
mv $PICONS_OUT_DIR/srp*/* $PICONS_OUT_DIR/
popd

echo "Done."
