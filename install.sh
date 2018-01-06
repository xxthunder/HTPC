#!/bin/bash -e

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

pushd $SETUPROOT

# Run ansible playbooks
ansible-playbook remote.yml lcd.yml vdr.yml kodi.yml kodi_config.yml

# Run old setup routines
sudo ./bin/setup.sh

popd

