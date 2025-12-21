#!/bin/bash

# **Docker installation script for Debian**

set -e # Exit immediately if any command fails, to avoid partial installations

sudo apt update
sudo apt upgrade -y

# ca-certificates: enables HTTPS trust
# curl: downloads external resources
# gnupg: validates cryptographic signatures (GPG)
sudo apt install -y ca-certificates curl gnupg

# Create directory for APT keyrings - keep repository keys isolated
# 0755 ensures proper read/execute permissions
sudo install -m 0755 -d /etc/apt/keyrings

# Download and register Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker’s official repository to APT
# arch: system architecture (amd64, arm64, etc.)
# signed-by: restricts trust to Docker’s key only
# lsb_release -cs: Debian codename (bookworm, bullseye, etc...)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

# Docker and core components
# - docker-ce: Docker engine
# - docker-ce-cli: Docker command-line client
# - containerd.io: container runtime
# - docker-buildx-plugin: advanced image builds
# - docker-compose-plugin: Docker Compose v2
sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Enable Docker as a system service, --now starts Docker immediately and ensures it starts on boot
sudo systemctl enable --now docker

docker --version
echo "Docker installation completed successfully!"