#!/bin/bash -e

SETUPROOT=$(pushd $(dirname $0) > /dev/null; pwd -P)

echo "Setting up SSH keys ..."

mkdir -p ~/.ssh
ssh-keygen -f ~/.ssh/ansible -t rsa -N ''
ssh-copy-id -i ~/.ssh/ansible localhost
echo "Done."
