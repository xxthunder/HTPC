#!/bin/bash -e

##################################################
#
# Create a link to a config file in this repo
#
# karsten.guenther@kamg.de
#
##################################################

SETUPROOT=$(pushd $(dirname $0)/.. > /dev/null; pwd -P)

if [ "$2" != "" ]
then
   USER=$2
else
   USER=root
fi

echo "Creating link $1 with user $USER."

if [ -e $SETUPROOT$1 ]
then
   sudo -u $USER mkdir -p $(dirname $1)
   sudo -u $USER rm -f $1 
   sudo -u $USER ln -s $SETUPROOT$1 $1
   ls $1
else
   echo "File to be linked to does not exist."
   exit 1
fi
