#!/bin/bash -e

##################################################
#
# DVB-C setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up dvb ..."

$SETUPROOT/bin/link.sh /lib/firmware/dvb-demod-si2168-a30-01.fw
$SETUPROOT/bin/link.sh /lib/firmware/dvb-demod-si2168-b40-01.fw

echo "Done."

