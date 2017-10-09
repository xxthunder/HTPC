#!/bin/bash -e

### Ubuntu's lightdm auto login setup ###

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up autologin ..."

$SETUPROOT/bin/link.sh /etc/lightdm/lightdm.conf

echo "Done."
