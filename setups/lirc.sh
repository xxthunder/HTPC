#!/bin/bash -e

##################################################
#
# Lirc setup
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up LIRC ..."

sudo service lirc stop || true
if ! (ps auxw | grep lircd | grep -v grep > /dev/null)
then
   $SETUPROOT/bin/link.sh /etc/lirc/hardware.conf
   $SETUPROOT/bin/link.sh /etc/lirc/lircd.conf
   $SETUPROOT/bin/link.sh /etc/lirc/lircmd.conf
   sudo service lirc start
fi

echo "Done."
