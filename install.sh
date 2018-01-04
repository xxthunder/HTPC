#!/bin/bash -e

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

pushd $SETUPROOT

# Run ansible playbooks
ansible-playbook test_sudo.yml vdr.yml kodi.yml

# Run old setup routines
sudo ./bin/setup.sh

popd

