#!/bin/bash

# from https://wiki.debian.org/KVM

set -e

cd ~

#sudo apt install -y qemu-system libvirt-daemon-system

sudo apt install -y --no-install-recommends qemu-system libvirt-clients libvirt-daemon-system

sudo usermod -aG libvirt $(whoami)

# reload the groups
su - $(whoami)
