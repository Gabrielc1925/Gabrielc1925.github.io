#!/bin/bash
set -eu -o pipefail

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to apt-get sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install necessary dependencies
sudo apt-get update
sudo apt-get install -y git-all nginx docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Nginx to start on boot using systemd
sudo systemctl enable nginx

# Get github pages files
cd ~
git clone https://github.com/Gabrielc1925/Gabrielc1925.github.io.git
cd Gabrielc1925.github.io
git checkout main

# Set up nginx configuration
cd nginx_setup
cp  -r -f conf.d /etc/nginx
cp -f nginx.conf /etc/nginx

# Set up nginx site html pages
mkdir /var/www/gabrielc1925.github.io
cd ~/Gabrielc1925.github.io
git checkout gh-pages
cp ~/Gabrielc1925.github.io/{_pages/dropdown,assets,blog,cv,news,projects,repositories,workflow,404.html,feed.xml,index.html,robots.txt,sitemap.xml} /var/www/gabrielc1925.github.io

# Reload nginx
nginx -s reload