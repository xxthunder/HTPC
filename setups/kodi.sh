#!/bin/bash -e

##################################################
#
# xorg setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up Kodi ..."

$SETUPROOT/setups/link.sh /home/xbmc/.kodi/userdata/keymaps/keyboard.xml xbmc

echo "Done."
