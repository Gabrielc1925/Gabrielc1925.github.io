---
layout: page
title: Terraform Deployment to Aws
description: Deploy to AWS from Packer AMI
img: assets/img/CI_CD_TF_AWS.png
importance: 2
category: work
related_publications: false
---

The next thing to do is to use Terraform to create resources in AWS from my Packer image. Terraform can use separate files to host data and variables, but I decided to keep it all in one file since this is a small project and that will help to simplify things.

I begun by maing a main.tf file to hold my Terraform configuration. The first block defines the provider plugins that are needed. For this project, I will be using the cloud platform for HCP, as that is where I stored my Packer files. I also will be using AWS, since that is where I will be deploying the image to.

```tf
terraform {
    cloud {
        organization = "Gabrielc1925-github-io"
        workspaces {
            name = "Gabrielc1925-github-io"
        }
    }
    required_providers {
        hcp = {
            source = "hashicorp/hcp"
            version = "~>0.94.1"
        }
        aws = {
            source  =   "hashicorp/aws"
            version     =   "~>5.0"

        }
    }
}
```

The next block defines the hcp provider, and is where I configure it. My terminal was missing a dependency to send out the authentication request to hcp in the normal way, so I could not get the script to run right away. I tried a number of different authentication methods described in the terraform documentation, including environment variables and credential files, but finally I decided to just move on with the rest of the terraform configuration and I just hard coded the arguments for client_id and client_secret. Obviously I am not going to include those below, but I will put a commented out placeholder for clarity's sake.
(the project_id and credential_file were from other attempts at authentication. I am leaving them for now so that when I go back to fix authentication I can save some time. No risk to having them exposed.)

```tf
provider "hcp" {
#    client_id = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#    client_secret = "xxxxxxxxxxxxxxxxxxXXX"
#    project_id = "b1bbb80d-e6cd-49c6-b855-bec80721fb28"
#    credential_file = "/home/gabrielc1925/.terraform.d/credentials.tfrc.json"
}
```

After that, I began to describe the resources that hcp would use. This is mainly defining a bucket for it to put information into, and to tell it where the ami created by Packer is located.

```tf
resource "hcp_packer_bucket" "Gabrielc1925-github-io" {
    name = "Gabrielc1925-githb-io"
}

resource "hcp_packer_channel" "latest" {
    name = "latest"
    bucket_name = "Gabrielc1925-github-io"
}

# Create local variable and get artifact ID from the base artifact
data "hcp_packer_version" "ResumeWebsiteBackup_AWS" {
    bucket_name = "Gabrielc1925-github-io"
    channel_name    = "latest"
}

data "hcp_packer_artifact" "Gabrielc1925-github-io" {
  bucket_name   = "Gabrielc1925-github-io"
  version_fingerprint = data.hcp_packer_version.ResumeWebsiteBackup_AWS.fingerprint
  platform      = "aws"
  region        = "us-east-1"
}
```

This information was found in my HCP Packer registry.

{% include figure.liquid loading="eager" path="assets/img/Packer_ami.png" title="HCP Packer Registry" class="img-fluid rounded z-depth-1" %}
Organization name removed for security.

Now that terraform knows where to find the ami created by Packer, it is time to begin configuring aws to prepare it to accept connections from terraform. Again, I had extended problems figuring out how to configure authentication to AWS that would play nicely with the rest of my terraform plan. The commented out code here is reflective of that.  
I ended up realizing that the best way to solve this was to provide environment variables to hcp in the Terraform HCP online portal. These environment variables allowed me to not have to hard code them into my terraform file or store environment variables locally. They are not referenced here, as hcp obtains them automatically when the terraform file is applied.

```tf
provider "aws" {
    region  =   "us-east-1"
    # profile = "default"
    # # The following two are used for local testing
    # shared_config_files = ["/home/gabrielc1925/.aws/config"]
    # shared_credentials_files = ["/home/gabrielc1925/.aws/credentials"]
    # The following two are for using with github actions saved credential secrets
    # access_key = AWS ACCESS_KEY_ID
    # secret_key = AWS_SECRET_ACCESS_KEY
}
```
