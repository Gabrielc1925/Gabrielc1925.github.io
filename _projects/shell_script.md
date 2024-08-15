---
layout: page
title: Shell Provisioner
description: Shell Provisioning for packer
img: assets/img/brackets.png
importance: 3
category: work
related_publications: false
---

**_This is a continuation of the script from the [packer page]({{site.baseurl}}{% link /\_projects/packer_aws_backup.md}), using shell scripting to provision resources rather than using ansible_**

For the shell script, the line referencing a provisioner within the packer manifest is different.

```r
    sources = [
        "source.amazon-ebs.github-pages",
    ]

    # Set up Nginx with HTML files from github pages
    provisioner "shell" {
        scripts = [
        "setup-deps-gh-pages.sh"
        ]
    }

    post-processor "manifest" {
        output     = "packer_manifest.json"
        strip_path = true
        custom_data = {
        version_fingerprint = packer.versionFingerprint
        }
    }

```

When the provisioner shell triggers the scripts listed in setup-deps-gh-pages.sh, the commands are input into the EC2 instance via SSH. The first few blocks establish procedures for handling response to errors, then download and install Docker and Nginx. Docker is not used for this step of the project, I just added it out of habit. Nginx is then set to start automatically on boot.

```sh

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

```

The next few blocks download the github repo, change to the main branch, and copy the nginx configuration files into the appropriate directories. The prebuilt html files that were output by jekyll for this site are then copied from the gh-pages branch into the appropriate location for nginx to use them. Finally, nginx is reloaded to enact the changes.

```sh

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

```
