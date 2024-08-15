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

The files use in this basic Packer deployment are:

```md
"/build.pkr.hcl",
"/ansible/playbook.yml",
"/.github/workflows/build-deploy-packer-aws.yml",
and
"/.github/scripts/create_channel_version.sh"
```

\page break

This workflow is triggered by the "build-deploy-packer-aws.yml" file.

The first block establishes the timing for when to run this github action. I set it to only run when a change was pushed to the gh-pages branch, as that is the final step after all other checks when a pull request is completed. I don't want to update my AMI unnecessarily, so I put this github action to run after all other actions are done.

```yml
name: Deploy to Packer and AWS

on:
push:
  tags: ["v[0-9].[0-9]+.[0-9]+"]
  branches:
    - "gh-pages"
```

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

\page break

Packer build begins by reading the build.pkr.hcl file and loading the plugins listed. It then lists the source for the AMI we will be building and provisioning. I went with a lightweight and low cost Ubuntu LTS 22.04 image as I do not need more than that for this project.

<!--- hcl is not a supported language, so I am using r for syntax highlighting --->

```r

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

```r

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

After that the build block specifies the source it is acting on (we only have one above, so this is it), and begins to provision the base image for us. It then runs a provisioner block when the EC2 instance is running, and inputs the commands from the source file. In this case it is the ansible playbook named playbook.yml

```r
# Set up Nginx with HTML files from Github Pages using Ansible
provisioner "ansible" {
  playbook_file = "./ansible/playbook.yml"
}

  # # Set up Nginx with HTML files from github pages
  # provisioner "shell" {
  #   scripts = [
  #     "setup-deps-gh-pages.sh"
  #   ]
  # }
```

\pagebreak

I previously used a shell script to provision the resources on the AMI, but have since switched it to use Ansible as a provisioner. Ansible is more relevant to real world applications, but I will include the shell scripting walkthrough [on a separate page]({{site.baseurl}}{% link \_projects/shell_script.md}) since I already wrote about it previously and as an example of past work.

When the provisioner script triggers, Ansible takes the playbook file listed and starts to run commands. Ansible has to be installed on the controller computer for this to work, as the ansible plugin references the host file.

First, I will install all of the required programs to the remote host. This is following the installation documentation from each program.

```yaml
---
- name: Install Docker, Nginx, and Git
  hosts: all
  become: true
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install Docker dependencies
      apt:
        name:
          - ca-certificates
          - curl
        state: present

    - name: Create directory for Docker keyring
      file:
        path: /etc/apt/keyrings
        state: directory
        mode: "0755"

    - name: Download Docker GPG key
      get_url:
        url: https://download.docker.com/linux/ubuntu/gpg
        dest: /etc/apt/keyrings/docker.asc

    - name: Set permissions for Docker GPG key
      file:
        path: /etc/apt/keyrings/docker.asc
        mode: "0644"

    - name: Add Docker repository
      block:
        - name: Get architecture
          command: dpkg --print-architecture
          register: architecture

        - name: Get OS codename
          shell: . /etc/os-release && echo "$VERSION_CODENAME"
          register: os_codename

        - name: Add Docker repository to apt sources
          copy:
            content: |
              deb [arch={{ architecture.stdout }} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu {{ os_codename.stdout }} stable
            dest: /etc/apt/sources.list.d/docker.list

    - name: Update apt cache after adding Docker repo
      apt:
        update_cache: true

    - name: Install Docker, Nginx, and Git
      apt:
        name:
          - git-all
          - nginx
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-buildx-plugin
          - docker-compose-plugin
        state: present
```

Next, I will start to configure the files to be served. This begins with creating a directory to store temporary files

```yaml
- name: configure files to be served
  hosts: all
  become: true
  tasks:
    - name: Create directory for temporary files
      file:
        path: /etc/tmp/github
        state: directory
        mode: "0775"
```

Then, I clone the github repo and copy the nginx configuration files that are needed:

```yaml
- name: get github pages files
  git:
    repo: "https://github.com/Gabrielc1925/Gabrielc1925.github.io.git"
    dest: /etc/tmp/github/Gabrielc1925.github.io
    version: main

- name: Copy nginx configuration files
  copy:
    src: /etc/tmp/github/Gabrielc1925.github.io/nginx_setup/nginx/
    dest: /etc/nginx
    remote_src: true
```

Next, I copy over the HTML files that have alreay been created by Jekyll. These are stored in the gh-pages branch.

```yaml
- name: Clone html files from github repo to temporary folder
  git:
    repo: "https://github.com/Gabrielc1925/Gabrielc1925.github.io.git"
    dest: /etc/tmp/github/gh-pages
    version: gh-pages
    update: yes

- name: synchronize html files from gh-pages to var so it can be served by nginx
  copy:
    src: /etc/tmp/github/gh-pages
    dest: /var/www
    remote_src: true
```

Finally, there is a set of commands to test nginx configuration and enable nginx when the system boots.

```yaml
- name: Check nginx configuration syntax
  command: nginx -t
  register: nginx_test
  ignore_errors: true

- name: Display nginx syntax check output if it failed
  debug:
    var: nginx_test.stderr_lines
  when: nginx_test.rc != 0

- name: Fail the playbook if nginx config is invalid
  fail:
    msg: "Nginx configuration is invalid. Please fix the errors and try again."
  when: nginx_test.rc != 0

- name: Restart nginx and enable on boot
  service:
    name: nginx
    enabled: true
    state: restarted
```

At this point Packer is complete and has created a working AMI on my AWS account. It then saves this AMI to the AWS registry, and saves the information needed to locate it later to the local file for upload to the Haschicorp cloud via HCP Packer.

```yaml
post-processor "manifest" {
output     = "packer_manifest.json"
strip_path = true
custom_data = {
version_fingerprint = packer.versionFingerprint
}
}
```

\pagebreak

The gh-actions workflow has one more job to run still, so it triggers the function to update the HCP Packer registry with the work we did, including the fingerprint that was saved in the last step.

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
