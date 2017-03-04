#!/bin/bash -e

##################################################
#
# Harmony hub via bluetooth for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up imon ..."

$SETUPROOT/bin/link.sh /usr/local/bin/harmony.sh
 
echo "Done."
