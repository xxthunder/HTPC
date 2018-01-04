#!/bin/bash -e

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

echo "Setting up ansible ..."

sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible

echo "Done."
