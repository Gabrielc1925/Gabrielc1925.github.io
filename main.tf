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

provider "hcp" {

#    project_id = "b1bbb80d-e6cd-49c6-b855-bec80721fb28"
#    credential_file = "/home/gabrielc1925/.terraform.d/credentials.tfrc.json"
}

resource "hcp_packer_bucket" "Gabrielc1925-github-io" {
    name = "Gabrielc1925-githb-io"
}

resource "hcp_packer_channel" "latest" {
    name = "latest"
    bucket_name = "Gabrielc1925-github-io"
}



provider "aws" {
    region  =   "us-east-1"
    # profile = "PowerUserAccess-978076141947"
    # # The following two are used for local testing
    # shared_config_files = ["/home/gabrielc1925/.aws/config"]
    # shared_credentials_files = ["/home/gabrielc1925/.aws/credentials"]
    # The following two are for using with github actions saved credential secrets

}
# source "amazon-ebs" "packer-secondary" {
#     source_ami  = data.hcp_packer_artifact.Gabrielc1925-github-io.external_identifier
# }

resource "aws_vpc" "gh_pages_backup_site" {
    # cidr_block = "10.0.0.0/24"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "main"
    }
}

resource "aws_internet_gateway" "gh_pages_ig" {
    vpc_id = aws_vpc.gh_pages_backup_site.id
}

resource "aws_subnet" "gh_pages_public_subnet" {
    vpc_id = aws_vpc.gh_pages_backup_site.id
    map_public_ip_on_launch = true
    cidr_block = "10.0.0.0/26"
    tags = {
        Name = "gh_pages_public_vpc"
    }
}

# resource "aws_network_interface" "gh_pages_network_interface" {
#     subnet_id = aws_subnet.gh_pages_public_subnet.id 

#     tags = {
#         Name = "gh_pages_public_network_interface"
#     }
# }

resource "aws_security_group" "gh_pages_ssh" {
    name = "gh_pages_ssh"
    description = "Allow SSH from EC2 instance connect"
    vpc_id = aws_vpc.gh_pages_backup_site.id
}

resource "aws_vpc_security_group_ingress_rule" "EC2InstanceConnect" {
    security_group_id = aws_security_group.gh_pages_ssh.id
    cidr_ipv4 = "18.206.107.24/29"
    ip_protocol = "tcp"
    from_port = 22
    to_port = 22
}
resource "aws_vpc_security_group_egress_rule" "EC2InstanceConnect" {
    security_group_id = aws_security_group.gh_pages_ssh.id
    cidr_ipv4 = "18.206.107.24/29"
    ip_protocol = "tcp"
    from_port = 22
    to_port = 22
}

resource "aws_route_table" "gh_pages_backup" {
    vpc_id = aws_vpc.gh_pages_backup_site.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gh_pages_ig.id
    }
    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.gh_pages_ig.id
    }
}

resource "aws_route_table_association" "gh_Pages_route_table" {
    subnet_id = aws_subnet.gh_pages_public_subnet.id
    route_table_id = aws_route_table.gh_pages_backup.id
}

resource "aws_instance" "gh-pages_backup" {
    ami = data.hcp_packer_artifact.Gabrielc1925-github-io.external_identifier
    instance_type = "t2.micro"
    # network_interface {
    #     network_interface_id = aws_network_interface.gh_pages_network_interface.id
    #     device_index = 0
    # }
    # associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.gh_pages_ssh.id]
    subnet_id = aws_subnet.gh_pages_public_subnet.id
    tags = {
        Name = "gh_pages_backup_instance"
    }
}


#TODO - Add public IPv4 address to EC2 Instance - #DONE
#TODO - Add Security group settings for SSH from EC2 and my IP #DONE
#TODO - Add internet gateway to gh_pages_publiv_vpc subnet #DONE