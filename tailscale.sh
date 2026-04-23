#!/usr/bin/env bash

sudo tailscale set --operator=$USER

# Only append if line isn't already present
grep -qxF 'net.ipv4.ip_forward = 1' /etc/sysctl.d/99-tailscale.conf || \
  echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf

grep -qxF 'net.ipv6.conf.all.forwarding = 1' /etc/sysctl.d/99-tailscale.conf || \
  echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf

sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
sudo systemctl restart tailscaled

# Network dependent

tailscale up --advertise-exit-node --advertise-routes=192.168.1.0/24,172.17.0.0/16,172.18.0.0/16

# Ports for services
tailscale serve --bg 8096
tailscale serve --bg 7359
# tailscale serve --bg 139
# tailscale serve --bg 445
# tailscale serve --bg 22
tailscale serve --bg 8080
tailscale serve --bg 9091
tailscale serve --bg 7070
# tailscale serve --bg 

sudo systemctl restart tailscaled
tailscale status