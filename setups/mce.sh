#!/bin/bash -e

##################################################
#
# IMON MCE remote setup for my HTPC
# (Harmony configuration: Microsoft MCE Keyboard)
#
# Based on this howto:
# http://kodi.wiki/view/HOW-TO:Setup_an_MCE_remote_control_in_Linux
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up imon_mce ..."

sudo apt-get install lirc
sudo apt-get install ir-keytable
sudo apt-get install inputlirc

# Create permanent device link
echo 'KERNEL=="event*",ATTRS{name}=="iMON Remote (15c2:0038)",SYMLINK="input/myremote"' > /etc/udev/rules.d/10-persistent-ir.rules
/etc/init.d/udev reload
udevadm trigger

$SETUPROOT/bin/link.sh /etc/rc.local
$SETUPROOT/bin/link.sh /etc/rc_keymaps/imon_mce
$SETUPROOT/bin/link.sh /home/xbmc/.kodi/userdata/Lircmap.xml xbmc
$SETUPROOT/bin/link.sh /etc/default/inputlirc
$SETUPROOT/bin/link.sh /etc/lirc/hardware.conf
$SETUPROOT/bin/link.sh /etc/lirc/lircd.conf
$SETUPROOT/bin/link.sh /etc/lirc/lircmd.conf

/etc/rc.local
/etc/init.d/inputlirc stop
/etc/init.d/inputlirc start

echo "Done."
