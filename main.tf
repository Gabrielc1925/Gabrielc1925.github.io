terraform {
    cloud {
        organization = "Gabrielc1925_github_io"
        workspaces {
            name = "Gabrielc1925_github_io"
        }
    }
    required_providers {
        # hcp = {
        #     source = "hashicorp/hcp"
        #     version = "~>0.94.1"
        # }
        aws = {
            source  =   "hashicorp/aws"
            version     =   "~>5.0"

        }
    }
}

provider "hcp" {
#    project_id = "b1bbb80d-e6cd-49c6-b855-bec80721fb28"
#    credential_file = "/home/gabrielc1925/.terraform.d/credentials.tfrc.json"
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
    # profile = "PowerUserAccess-978076141947"
    # # The following two are used for local testing
    # shared_config_files = ["/home/gabrielc1925/.aws/config"]
    # shared_credentials_files = ["/home/gabrielc1925/.aws/credentials"]
    # The following two are for using with github actions saved credential secrets

}

resource "aws_vpc" "gh_pages_backup_site" {
    cidr_block = "10.0.0.0/24"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "main"
    }
}

resource "aws_subnet" "gh_pages_public_subnet" {
    vpc_id = aws_vpc.gh_pages_backup_site.id
    cidr_block = "10.0.0.0/26"
    tags = {
        Name = "gh_pages_public_vpc"
    }
}

resource "aws_network_interface" "gh_pages_network_interface" {
    subnet_id = aws_subnet.gh_pages_public_subnet.id
    tags = {
        Name = "gh_pages_public_network_interface"
    }
}

resource "aws_instance" "gh-pages_backup" {
    ami = data.hcp_packer_artifact.Gabrielc1925-github-io.id
    instance_type = "t2.micro"
    network_interface {
        network_interface_id = aws_network_interface.gh_pages_network_interface.id
        device_index = 0
    }
    tags = {
        Name = "gh_pages_backup_instance"
    }
}
