---
layout: page
title: Packer Backup
description: Automate AMI Creation
img: assets/img/CI_CD_pipeline.png
importance: 1
category: work
related_publications: false
---

First on my list of things to do after getting this website up and running is to build up my portfolio of projects. I will be using the Hashicorp suite of products as they are widely used and a good base level of knowledge for anyone who wishes to branch out into other platforms.

This first step in the process is to use Packer to create an Amazon Machine Image for use on AWS. This is a very small part of the overall CI/CD workflow, but I am going to do it in steps so that I can explain each file in depth.

The files for this project can be found in the Github repo for this website: [github.com/gabrielc1925/gabrielc1925.github.io](https://github.com/Gabrielc1925/Gabrielc1925.github.io).

``The files use in this basic Packer deployment are:
`
"/build.pkr.hcl",
"/setup-deps-gh-pages.sh",
"/.github/workflows/build-deploy-packer-aws.yml",
and
"/.github/scripts/create_channel_version.sh"

````

This workflow is triggered by the "build-deploy-packer-aws.yml" file.

The first block establishes the timing for when to run this github action. I set it to only run when a change was pushed to the gh-pages branch, as that is the final step after all other checks when a pull request is completed. I don't want to update my AMI unnecessarily, so I put this github action to run after all other actions are done.

```yml file=build-deploy-packer-aws.yml
name: Deploy to Packer and AWS

on:
push:
  tags: ["v[0-9].[0-9]+.[0-9]+"]
  branches:
    - "gh-pages"
````

The environment variables and where to find them are then defined, and then the jobs block begins.
The first job copies the repo with checkout and links it in an environment variable so that it can be accessed by later parts of the gh-actions scripts. It then links the AWS credentials stored in the gh secrets manager to local env variables for this set of functions.

```yml
jobs:
  build-artifact:
    name: Build
    runs-on: ubuntu-latest
    outputs:
      version_fingerprint: ${{ steps.hcp.outputs.version_fingerprint }}
    steps:
      - name: Checkout Repository
        uses: actions/checkout@3df4ab11eba7bda6032a0b82a6bb43b11571feac # v4.0.0

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@8c3f20df09ac63af7b3ae3d7c91f105f857d8497 # v4.0.0
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
```

The gh-actions script then begins to run Packer. It initializes the plugins required, then either runs a normal packer build command or includes a tag when running packer build to keep track of major deployments.
Finally, it records the Packer version fingerprint for use by later scripts and applications.

```yml

    - name: Packer Init
        run: packer init .

    - name: Packer Build - Branches
        if: startsWith(github.ref, 'refs/heads/')
        run: packer build .

    - name: Packer Build - Tags
        if: startsWith(github.ref, 'refs/tags/v')
        run: HCP_PACKER_BUILD_FINGERPRINT=$(date +'%m%d%YT%H%M%S') packer build .

    - name: Get HCP Packer version fingerprint from Packer Manifest
        id: hcp
        run: |
            last_run_uuid=$(jq -r '.last_run_uuid' "./packer_manifest.json")
            build=$(jq -r '.builds[] | select(.packer_run_uuid == "'"$last_run_uuid"'")' "./packer_manifest.json")
            version_fingerprint=$(echo "$build" | jq -r '.custom_data.version_fingerprint')
            echo "::set-output name=version_fingerprint::$version_fingerprint"

```

Packer build begins by reading the build.pkr.hcl file and loading the plugins listed. It then lists the source for the AMI we will be building and provisioning. I went with a lightweight and low cost Ubuntu LTS 22.04 image as I do not need more than that for this project.

<!--- hcl is not a supported language, so I am using js for syntax highlighting --->

```js

    packer {
    required_plugins {
        amazon = {
        source  = "github.com/hashicorp/amazon"
        version = "~> 1.3.2"
        }
    }
    }

    source "amazon-ebs" "github-pages" {
    region = "us-east-1"
    source_ami    = "ami-04a81a99f5ec58529"
    instance_type  = "t2.micro"
    ssh_username   = "ubuntu"
    ami_name    = "Gabrielc1925-github-io_{{timestamp}}"
    ami_regions = ["us-east-1"]
    }

```

The next step is to begin our build block. The first step is to connect to the HCP packer registry and create a bucket to track our changes and store any completed AMIs in later steps.

```js

    build {
    # HCP Packer settings
    hcp_packer_registry {
        bucket_name = "Gabrielc1925-github-io"
        description = <<EOT
    This is an image for a backup of the github pages site for gabrielc1925
        EOT

        bucket_labels = {
        "hashicorp-learn" = "learn-packer-github-actions",
        }
    }
    }

```

After that the build block specifies the source it is acting on (we only have one above, so this is it), and begins to provision the base image for us. It then runs a provisioner block when the EC2 instance is running, and inputs the commands from the shell scripts specified by the file named "setup-deps-gh-pages.sh."

(After that there is a post processer function that prints the outputs to a file, lists the paths from the volume root for each, and tags the file with the fingerprint from this particular version. This part is not terribly important for our current setup, but can be used later with Terraform to track changed assets. I won't talk more about those 5 lines of code in this article.)

```js

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

At this point Packer is complete and has created a working AMI on my AWS account. It has not saved this AMI to a registry or set up long-term management with Terraform, but the script worked so it is the first step of a CI/CD workflow.

The gh-actions workflow has one more job to run still, so it triggers the function to update the HCP Packer registry with the work we did.

```yml

update-hcp-packer-channel:
name: Update HCP Packer channel
needs: ["build-artifact"]
runs-on: ubuntu-latest
steps: - name: Checkout Repository
uses: actions/checkout@3df4ab11eba7bda6032a0b82a6bb43b11571feac # v4.0.0

        - name: Create and set channel
            working-directory: .github/scripts
            run: |
            channel_name=$( echo ${{github.ref_name}} | sed 's/\./-/g')
            ./create_channel_version.sh $HCP_BUCKET_NAME $channel_name "${{ needs.build-artifact.outputs.version_fingerprint }}"

```

This triggers the helper script based in "create_channel_version.sh," which records the changes to the Packer registry in the bucket we specified. This section is not something that I wrote, I just copied it from Hashicorp's example repo and ensured no modifications were needed due to my region or bucket name.
The script uses a bunch of metadata to ensure that the files generated have unique names so they will work with HCP registry

```sh

    #! /usr/bin/env bash

    set -eEuo pipefail

    usage() {
    cat <<EOF
    This script is a helper for setting a channel version in HCP Packer
    Usage:
    $(basename "$0") <bucket_slug> <channel_name> <version_fingerprint>
    ---
    Requires the following environment variables to be set:
    - HCP_CLIENT_ID
    - HCP_CLIENT_SECRET
    - HCP_ORGANIZATION_ID
    - HCP_PROJECT_ID
    EOF
    exit 1
    }

    # Entry point
    test "$#" -eq 3 || usage

    bucket_slug="$1"
    channel_name="$2"
    version_fingerprint="$3"
    auth_url="${HCP_AUTH_URL:-https://auth.hashicorp.com}"
    api_host="${HCP_API_HOST:-https://api.cloud.hashicorp.com}"
    base_url="$api_host/packer/2023-01-01/organizations/$HCP_ORGANIZATION_ID/projects/$HCP_PROJECT_ID"

    # If on main branch, set channel to release
    if [ "$channel_name" == "main" ]; then
    channel_name="release"
    fi

    echo "Attempting to assign version ${version_fingerprint} in bucket ${bucket_slug} to channel ${channel_name}"

    # Authenticate
    response=$(curl --request POST --silent \
    --url "$auth_url/oauth/token" \
    --data grant_type=client_credentials \
    --data client_id="$HCP_CLIENT_ID" \
    --data client_secret="$HCP_CLIENT_SECRET" \
    --data audience="https://api.hashicorp.cloud")
    api_error=$(echo "$response" | jq -r '.error')
    if [ "$api_error" != null ]; then
    echo "Failed to get access token: $api_error"
    exit 1
    fi
    bearer=$(echo "$response" | jq -r '.access_token')

    # Get or create channel
    echo "Getting channel ${channel_name}"
    response=$(curl --request GET --silent \
    --url "$base_url/buckets/$bucket_slug/channels/$channel_name" \
    --header "authorization: Bearer $bearer")
    api_error=$(echo "$response" | jq -r '.message')
    if [ "$api_error" != null ]; then
    echo "Channel ${channel_name} like doesn't exist, creating new channel"
    # Channel likely doesn't exist, create it
    api_error=$(curl --request POST --silent \
        --url "$base_url/buckets/$bucket_slug/channels" \
        --data-raw '{"name":"'"$channel_name"'"}' \
        --header "authorization: Bearer $bearer" | jq -r '.error')
    if [ "$api_error" != null ]; then
        echo "Error creating channel: $api_error"
        exit 1
    fi
    fi

    # Update channel to point to version
    echo "Updating channel ${channel_name} to version fingerprint ${version_fingerprint}"
    api_error=$(curl --request PATCH --silent \
    --url "$base_url/buckets/$bucket_slug/channels/$channel_name" \
    --data-raw '{"version_fingerprint": "'$version_fingerprint'", "update_mask": "versionFingerprint"}' \
    --header "authorization: Bearer $bearer" | jq -r '.message')
    if [ "$api_error" != null ]; then
        echo "Error updating channel: $api_error"
        exit 1
    fi

```

After that, the gh-actions workflow is completed and the AMI generated by Packer is terminated.

The next steps are to set up terraform for this site, and to confure a system to fail over to AWS in case of an outage.
