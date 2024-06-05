#!/bin/bash

# run this command with `sudo`

set -ex

mkdir /tmp/docker

systemctl stop docker

#systemctl status docker

rsync -avxP /var/lib/docker /tmp/docker

mv /var/lib/docker /var/lib/docker.bkp

ln -s /tmp/docker /var/lib/docker

systemctl start docker

#systemctl status docker

# TODO: add an if check here to ensure docker started successfully
rm -r /var/lib/docker.bkp
