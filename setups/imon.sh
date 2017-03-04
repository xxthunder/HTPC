#!/bin/bash -e

##################################################
#
# IMON LCD display setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up imon ..."

$SETUPROOT/bin/link.sh /etc/udev/rules.d/imonlcd.rules
$SETUPROOT/bin/link.sh /usr/local/bin/vdrtimer.sh
$SETUPROOT/bin/link.sh /usr/local/bin/imontimer.sh
$SETUPROOT/bin/link.sh /usr/local/bin/imon
 
echo "Done."
