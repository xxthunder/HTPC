#!/bin/bash -e

##################################################
#
# IMON MCE remote setup for my HTPC
# (Harmony configuration: Microsoft MCE Keyboard)
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up imon_mce ..."

sudo apt-get install ir-keytable

$SETUPROOT/bin/link.sh /etc/rc.local
$SETUPROOT/bin/link.sh /etc/rc_keymaps/imon_mce

echo "Done."
