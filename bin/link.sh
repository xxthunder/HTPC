#!/bin/bash -e

##################################################
#
# Create a system config file
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

echo "Creating $1 with user $USER ..."

if [ -e $SETUPROOT$1 ]
then
   sudo -u $USER mkdir -p $(dirname $1)
   sudo -u $USER rm -f $1 
#   sudo -u $USER ln -s $SETUPROOT$1 $1
   sudo -u $USER cp $SETUPROOT$1 $1
   ls $1
else
   echo "File $SETUPROOT$1 does not exist."
   exit 1
fi
