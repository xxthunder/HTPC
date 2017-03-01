#!/bin/bash -e

##################################################
#
# xorg setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up imon ..."

$SETUPROOT/setups/link.sh /etc/udev/rules.d/imonlcd.rules

echo "Done."
