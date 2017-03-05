#! /bin/bash

address="00:04:20:F5:FA:B7"

while (sleep 1)
do
   connected=`hidd --show` > /dev/null
   if [[ ! $connected =~ .*$address.* ]]
   then
      echo "Trying to connect to $address ..."
      hidd --connect $address > /dev/null 2>&1
   else
      echo "Connected to $address."
   fi
done
