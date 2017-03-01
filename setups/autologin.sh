#!/bin/bash -e

##################################################
#
# Ubuntu auto login setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up autologin ..."

$SETUPROOT/setups/link.sh /etc/lightdm/lightdm.conf

echo "Done."

