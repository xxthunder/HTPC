#!/bin/bash -e

##################################################
#
# Kodi setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up Kodi ..."

$SETUPROOT/bin/link.sh /home/xbmc/.kodi/userdata/keymaps/keyboard.xml xbmc
$SETUPROOT/bin/link.sh /home/xbmc/.kodi/userdata/LCD.xml xbmc

echo "Done."
