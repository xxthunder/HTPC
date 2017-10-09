#!/bin/bash -e

### Some other system config stuff ###

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Setting up stuff ..."

$SETUPROOT/bin/link.sh /etc/sysctl.conf
$SETUPROOT/bin/link.sh /etc/systemd/logind.conf

echo "Done."

