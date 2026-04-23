#!/usr/bin/env bash

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "debian" ]; then
        echo "This script requires Debian. Detected: ${PRETTY_NAME:-unknown}"
        exit 1
    fi
else
    echo "Cannot determine OS. /etc/os-release not found."
    exit 1
fi

# Update everything beforehand

sudo apt update -y
sudo apt upgrade -y

mkdir -p \
  ~/trans/config \
  ~/trans/downloads \
  ~/trans/complete \
  ~/bin \
  ~/temp \
  ~/etc \
  ~/man \
  ~/not \
  ~/src \
  ~/vcs \
  ~/etc \
  ~/dta \
  ~/lib \
  ~/tst \
  ~/docker
  
echo ">> Directories created..."

# Install Ansible
sudo apt install ansible -y

# Run the playbook (needs sudo for apt/systemd)
ansible-playbook system_setup.yml --ask-become-pass

newgrp docker

echo ">> Running dotfiles setup..."
bash dotfiles.sh

echo ">> Running Intel GPU setup..."
bash intel.sh

echo ">> Running Tailscale setup..."
bash tailscale.sh
