#!/bin/bash

set -e

sudo mkdir /tmp/docker

sudo systemctl stop docker

sudo systemctl status docker

sudo rsync -avxP /var/lib/docker /tmp/docker

sudo mv /var/lib/docker /var/lib/docker.bkp

sudo ln -s /tmp/docker /var/lib/docker

sudo systemctl start docker

sudo systemctl status docker

echo "if runner execute: sudo rm -r /var/lib/docker.bkp"
