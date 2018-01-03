#!/bin/bash -e

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

pushd $SETUPROOT
ansible-playbook test_sudo.yml vdr.yml kodi.yml
popd

