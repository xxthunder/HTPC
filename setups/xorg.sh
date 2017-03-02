#!/bin/bash -e

##################################################
#
# xorg setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up xorg ..."

$SETUPROOT/bin/link.sh /etc/X11/xorg.conf
$SETUPROOT/bin/link.sh /etc/X11/toshiba_lcd_edid.bin

echo "Done."

