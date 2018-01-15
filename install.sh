#!/bin/bash -e

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

pushd $SETUPROOT

# Run ansible playbooks
ansible-playbook system.yml remote.yml lcd.yml vdr.yml picons.yml kodi.yml

# Run old setup routines
sudo ./bin/setup.sh

popd

