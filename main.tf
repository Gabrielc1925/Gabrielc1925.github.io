terraform {
    backend "remnote" {
        remote {
            hostname = "app.terraform.io"
            organization = "Gabrielc1925-github-io"
            workspaces {
                name = "Gabrielc1925-github-io"
            }
        }
    }
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


# My terminal does not have a browser linked to xdg-open, so I cannot use the normal method of authenticating to hcp.
# So far I have been hard coding arguments for client_id and client_secret (and then removing them before writing a commit)

provider "hcp" {
    # client_id = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    # client_secret = "xxxxxxxxxxxxxxxxxxXXX"
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

# This is an attempt to use prebuilt resources to fix configuration problems an allow for continuing configuration of automatic failover.
data "aws_subnet" "public" {
    id = "subnet-0716f207e424b5e72"
}

data "aws_security_group" "public" {
    id = "sg-091c66d85701d3e0c"
}


# All of the commented out settings below were to make a custom VPN.  I removed them and instead created a link to a vpn that I created using the aws console interface.
# After I created a manually managed VPN, I was able to determine after some extended testing that my settings in nginx were actually at fault"
# I had left out one line in my nginx conf.d file, and had not allowed nginx to listen to requests from ipv4. 
# I have not reenabled them, but the configuration should be sufficient to work.  It was working fine, but I was not able to reach the served site from an exterior ip address. 



# resource "aws_vpc" "gh_pages_backup_site" {
#     cidr_block = "10.0.0.0/24"
#     enable_dns_support = true
#     enable_dns_hostnames = true
#     tags = {
#         Name = "tf_gh_pages_vpc"
#     }
# }

# resource "aws_internet_gateway" "gh_pages_ig" {
#     vpc_id = aws_vpc.gh_pages_backup_site.id
# }

# resource "aws_subnet" "gh_pages_public_subnet" {
#     vpc_id = aws_vpc.gh_pages_backup_site.id
#     map_public_ip_on_launch = true
#     cidr_block = "10.0.0.0/26"
#     tags = {
#         Name = "tf_gh_pages_public_subnet"
#     }
# }

# resource "aws_network_interface" "gh_pages_network_interface" {
#     subnet_id = aws_subnet.gh_pages_public_subnet.id 

#     tags = {
#         Name = "tf_gh_pages_eni"
#     }
# }

# resource "aws_security_group" "gh_pages_ssh" {
#     name = "tf_gh_pages_ssh"
#     description = "Allow SSH from EC2 instance connect"
#     vpc_id = aws_vpc.gh_pages_backup_site.id
# }

# resource "aws_vpc_security_group_ingress_rule" "AllowAll" {
#     security_group_id = aws_security_group.gh_pages_ssh.id
#     ip_protocol = "all"
#     from_port = 0
#     to_port = 0
#     cidr_ipv4 = aws_vpc.gh_pages_backup_site.cidr_block
# }

# resource "aws_vpc_security_group_ingress_rule" "EC2InstanceConnect" {
#     security_group_id = aws_security_group.gh_pages_ssh.id
#     cidr_ipv4 = "18.206.107.24/29"
#     ip_protocol = "tcp"
#     from_port = 22
#     to_port = 22
# }
# resource "aws_vpc_security_group_egress_rule" "EC2InstanceConnect" {
#     security_group_id = aws_security_group.gh_pages_ssh.id
#     cidr_ipv4 = "18.206.107.24/29"
#     ip_protocol = "tcp"
#     from_port = 22
#     to_port = 22
# }

# resource "aws_vpc_security_group_ingress_rule" "http" {
#     security_group_id = aws_security_group.gh_pages_ssh.id
#     cidr_ipv4 = aws_vpc.gh_pages_backup_site.cidr_block
#     ip_protocol = "tcp"
#     from_port = 80
#     to_port = 80
# }
# resource "aws_vpc_security_group_egress_rule" "http" {
#     security_group_id = aws_security_group.gh_pages_ssh.id
#     cidr_ipv4 = aws_vpc.gh_pages_backup_site.cidr_block
#     ip_protocol = "tcp"
#     from_port = 80
#     to_port = 80
# }

# resource "aws_vpc_security_group_ingress_rule" "https" {
#     security_group_id = aws_security_group.gh_pages_ssh.id
#     cidr_ipv4 = aws_vpc.gh_pages_backup_site.cidr_block
#     ip_protocol = "tcp"
#     from_port = 443
#     to_port = 443
# }
# resource "aws_vpc_security_group_egress_rule" "https" {
#     security_group_id = aws_security_group.gh_pages_ssh.id
#     cidr_ipv4 = aws_vpc.gh_pages_backup_site.cidr_block
#     ip_protocol = "tcp"
#     from_port = 443
#     to_port = 443
# }

# resource "aws_route_table" "gh_pages_backup" {
#     vpc_id = aws_vpc.gh_pages_backup_site.id

#     route {
#         cidr_block = "0.0.0.0/0"
#         gateway_id = aws_internet_gateway.gh_pages_ig.id
#     }
#     # route {
#     #     ipv6_cidr_block = "::/0"
#     #     gateway_id = aws_internet_gateway.gh_pages_ig.id
#     # }
# }

# resource "aws_route_table_association" "gh_Pages_route_table" {
#     subnet_id = aws_subnet.gh_pages_public_subnet.id
#     route_table_id = aws_route_table.gh_pages_backup.id
# }

resource "aws_instance" "gh-pages_backup" {
    ami = data.hcp_packer_artifact.Gabrielc1925-github-io.external_identifier
    instance_type = "t2.micro"
    # network_interface {
    #     network_interface_id = aws_network_interface.gh_pages_network_interface.id
    #     device_index = 0
    # }
    associate_public_ip_address = true
    security_groups = [data.aws_security_group.public.id]
    # vpc_security_group_ids = [aws_security_group.gh_pages_ssh.id]
    subnet_id = data.aws_subnet.public.id
    tags = {
        Name = "gh_pages_backup_instance"
    }
}


# per https://docs.nginx.com/nginx/deployment-guides/amazon-web-services/ec2-instances-for-nginx/ :
# security group **inbound** settings for http have to be enabled. (enabled all for now, will need to change settings later if exposure to all is not wanted.)

