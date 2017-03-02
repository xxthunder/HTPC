#!/bin/bash -e

##################################################
#
# xorg setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up sysctl ..."

$SETUPROOT/bin/link.sh /etc/sysctl.conf

echo "Done."

