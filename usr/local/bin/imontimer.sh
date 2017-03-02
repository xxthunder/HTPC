#!/bin/bash

##################################################
#
# Program imon lcd display alarm.
#
# karsten.guenther@kamg.de
#
##################################################

THISROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

echo "Wake up in $1 minutes."
if [ "$1" -gt "0" ]
then
   perl -I$THISROOT/imon/RFLib $THISROOT/imon/lcdalarm.pl -m $1
fi

