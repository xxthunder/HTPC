#!/bin/bash -e

##################################################
#
# Create a link to a config file in this repo
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

echo "Creating link /$1."

if [ -f $SETUPROOT/$1 ]
then
   sudo mkdir -p $(dirname $1)
   sudo rm -f /$1 
   sudo ln -s $SETUPROOT/$1 /$1
   ls /$1
else
   echo "File to be linked to does not exist."
   exit 1
fi

