#!/bin/bash -e

##################################################
#
# Ubuntu's lightdm auto login setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up autologin ..."

$SETUPROOT/bin/link.sh /etc/lightdm/lightdm.conf

echo "Done."

