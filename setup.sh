#!/bin/bash -e

##################################################
#
# HTPC setup
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

echo "Setup root directory: $SETUPROOT"

sudo service vdr stop || true
if ! (ps auxw | grep vdr | grep -v grep > /dev/null)
then
   sudo rm /var/lib/vdr/remote.conf
   sudo ln -s $SETUPROOT/var/lib/vdr/remote.conf /var/lib/vdr/remote.conf
   sudo service vdr start
fi

