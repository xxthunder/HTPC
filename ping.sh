#!/bin/bash -e

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

pushd $SETUPROOT
ansible production --inventory-file=hosts --module-name=ping
popd

