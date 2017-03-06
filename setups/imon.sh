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

sudo service lcdproc stop || true
sudo service LCDd stop || true
sudo apt-get install lcdproc

sudo find /etc -name "*LCDd" | grep "/etc/rc.*\.d/" | xargs sudo rm -f
sudo rm -f /etc/init.d/LCDd.conf

$SETUPROOT/bin/link.sh /etc/udev/rules.d/imonlcd.rules
$SETUPROOT/bin/link.sh /usr/local/bin/vdrtimer.sh
$SETUPROOT/bin/link.sh /usr/local/bin/imontimer.sh
$SETUPROOT/bin/link.sh /usr/local/bin/imon

sudo service LCDd stop || true

sleep 5
if ! (ps auxw | grep LCDd | grep -v grep > /dev/null)
then
   $SETUPROOT/bin/link.sh /etc/LCDd.conf
   $SETUPROOT/bin/link.sh /etc/init/lcdproc.conf
fi

echo "Done."
