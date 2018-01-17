#!/bin/bash -e

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

pushd $SETUPROOT

# Run ansible playbooks
ansible-playbook xorg.yml lightdm.yml system.yml remote.yml imon.yml vdr.yml picons.yml kodi.yml

popd

echo "Done."
