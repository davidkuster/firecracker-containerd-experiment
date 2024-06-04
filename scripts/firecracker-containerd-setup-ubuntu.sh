#!/bin/bash

cd ~

# Install git, Go 1.21, make, curl
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt update
sudo apt install -y \
  golang-1.21 \
  make \
  git \
  curl \
  e2fsprogs \
  util-linux \
  bc \
  gnupg

# Ubuntu's Go 1.21 package installs "go" command under /usr/lib/go-1.21/bin
export PATH=/usr/lib/go-1.21/bin:$PATH

cd ~

# Install Docker CE
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker $(whoami)

# Install device-mapper
sudo apt install -y dmsetup

