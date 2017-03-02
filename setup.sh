#!/bin/bash -e

##################################################
#
# xorg setup for my HTPC
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

echo "Setting up HTPC environment ..."

for i in $SETUPROOT/setups/*.sh
do
   echo "Running setup script $i"
   $i
done

