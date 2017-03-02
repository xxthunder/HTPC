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
$SETUPROOT/setups/link.sh /usr/local/bin/vdrtimer.sh
$SETUPROOT/setups/link.sh /usr/local/bin/imontimer.sh
$SETUPROOT/setups/link.sh /usr/local/bin/imon
$SETUPROOT/setups/link.sh /etc/init/vdr.conf
 
echo "Done."
