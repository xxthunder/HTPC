#!/bin/bash -e

##################################################
#
# VDR HTPC setup
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up VDR ..."

sudo service vdr stop || true
if ! (ps auxw | grep vdr | grep -v grep > /dev/null)
then
   $SETUPROOT/bin/link.sh /etc/default/vdr
   $SETUPROOT/bin/link.sh /etc/vdr/conf.d/00-vdr.conf
   $SETUPROOT/bin/link.sh /etc/init/vdr.conf
   sudo service vdr start
fi

echo "Done."
