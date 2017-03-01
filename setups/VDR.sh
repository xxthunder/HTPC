#!/bin/bash -e

##################################################
#
# HTPC setup
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up VDR ..."

sudo service vdr stop || true
if ! (ps auxw | grep vdr | grep -v grep > /dev/null)
then
   sudo service vdr start
fi

echo "Done."
