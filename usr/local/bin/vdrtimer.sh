#!/bin/bash

##################################################
#
# Program lcd display alarm during shutdown.
#
# karsten.guenther@kamg.de
#
##################################################

THISROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

# get the relative time difference in seconds between next vdr timer and now
wakeuptime=$(svdrpsend -d localhost NEXT rel|grep 250 |cut -f3 -d' '|tr -d '\r')
let difftimeminutes=24*60

if [ "$wakeuptime" = "" ]; then
   echo "No timer programmed."
elif [ "$wakeuptime" -gt "300" ]; then
   let difftimeminutes=($wakeuptime)/60-2
else
   echo "Currently recording."
fi

$THISROOT/imontimer.sh $difftimeminutes
