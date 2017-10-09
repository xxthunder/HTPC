#!/bin/bash -e

##################################################
#
# Some other stuff for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up stuff ..."

$SETUPROOT/bin/link.sh /etc/sysctl.conf
$SETUPROOT/bin/link.sh /etc/systemd/logind.conf

echo "Done."

