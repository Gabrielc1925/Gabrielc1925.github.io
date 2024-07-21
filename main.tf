terraform {
    cloud {
        organization = "Gabrielc1925_github_io"
        workspaces {
            name = "Gabrielc1925_github_io"
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

# Create local variable and get artifact ID from the base artifact
data "hcp_packer_artifact" "Gabrielc1925-github-io" {
  bucket_name   = "Gabrielc1925-github-io"
  channel_name  = "latest"
  platform      = "aws"
  region        = "us-east-1"
}

provider "aws" {
    region  =   "us-east-1"
}

resource "aws_vpc" "gh_pages_backup_site" {
    cidr_block = "10.0.0.0/24"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "main"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.gh_pages_backup_site
    cidr_block = "10.0.0.0/26"
    tags = {
        Name = "gh_pages_public_vpc"
    }
}

resource "aws_instance" "gh-pages_backup" {
    ami = data.hcp_packer_artifact.Gabrielc1925-github-io
    instance_type = "t2.micro"
    tags = {
        Name = "gh_pages_backup_instance"
    }
}
