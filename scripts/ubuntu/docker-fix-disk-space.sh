#!/bin/bash

# run this command with `sudo`

set -ex

sudo mkdir /tmp/docker

sudo systemctl stop docker

#systemctl status docker

sudo rsync -avxP /var/lib/docker /tmp/docker

sudo mv /var/lib/docker /var/lib/docker.bkp

sudo ln -s /tmp/docker /var/lib/docker

sudo systemctl start docker

#systemctl status docker

# TODO: add an if check here to ensure docker started successfully
sudo rm -r /var/lib/docker.bkp
