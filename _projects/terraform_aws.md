---
layout: page
# title: Terraform Deployment to Aws
permalink: /projects/terraform_aws/
# description: Deploy to AWS from Packer AMI
# img: assets/img/terraform-deploy-project.jpg
# importance: 2
# category: work
related_publications: false
---

# Terraform Deployment to AWS

The next thing to do is to use Terraform to create resources in AWS from my Packer image. Terraform can use separate files to host data and variables, but I decided to keep it all in one file since this is a small project and that will help to simplify things.

I begun by maing a [main.tf](https://github.com/Gabrielc1925/Gabrielc1925.github.io/blob/main/main.tf) file to hold my Terraform configuration. The first block defines the provider plugins that are needed. For this project, I will be using the cloud platform for HCP, as that is where I stored my Packer files. I also will be using AWS, since that is where I will be deploying the image to.

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

Next is where my VPC setup section would go. However, I was having a problem where I could not access my website from the IP address provided by the EC2 instance. I tried everything, but could not figure out the problem.  
In an attempt to remove confounding factors to isolate the problem, I commented out all of my VPC-provisioning blocks, and instead made a VPC using the AWS console and linked it to my terraform code. This way, I knew that the VPC was set up correctly and the problem was not with my terraform code.

```tf
# This is an attempt to use prebuilt resources to fix configuration problems and allow for continuing configuration of automatic failover.
data "aws_subnet" "public" {
    id = "subnet-0716f207e424b5e72"
}

data "aws_security_group" "public" {
    id = "sg-091c66d85701d3e0c"
}

```

After provisioning resources with this, I still could not access the served webpage, so I assumed the problem was somewhere within the instance.
Finally, I realized that I had forgot to allow the nginx server to listen on ipv4. So my ipv4 address that I was trying to connect to was not being recognized internally by the nginx server.

One line of code later, I was able to access my webpage. I fixed the offending code in the source file, and was able to move on to checking if my teraform code could provision a VPC.

First, I started with basic provisioning of a VPC and the various resources within a VPC including an internet gateway, a network interface, and a subnet.

```tf
#VPC
resource "aws_vpc" "gh_pages_backup_site" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "tf_gh_pages_vpc"
  }
}

resource "aws_internet_gateway" "gh_pages_ig" {
  vpc_id = aws_vpc.gh_pages_backup_site.id
}

resource "aws_network_interface" "gh_pages_network_interface" {
  subnet_id = aws_subnet.gh_pages_public_subnet.id

  tags = {
    Name = "tf_gh_pages_eni"
  }
}

resource "aws_subnet" "gh_pages_public_subnet" {
  vpc_id                  = aws_vpc.gh_pages_backup_site.id
  map_public_ip_on_launch = true
  cidr_block              = "10.0.0.0/26"
  tags = {
    Name = "tf_gh_pages_public_subnet"
  }
}

```

Next, I created a route table and route table association to ensure all traffic into or out of the subnet was directed to the internet gateway.

```tf

#ROUTE TABLE
resource "aws_route_table" "gh_pages_backup" {
  vpc_id = aws_vpc.gh_pages_backup_site.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gh_pages_ig.id
  }
  # route {
  #     ipv6_cidr_block = "::/0"
  #     gateway_id = aws_internet_gateway.gh_pages_ig.id
  # }
}

resource "aws_route_table_association" "gh_Pages_route_table" {
  subnet_id      = aws_subnet.gh_pages_public_subnet.id
  route_table_id = aws_route_table.gh_pages_backup.id
}

```

Next I provisioned a security group. I left way more open than I would in a real production setting, as I was just learning how to write terraform code for different ports, and my focus is currently on just having a functional example product to learn from in future steps.

```tf

#SECURITY GROUP
resource "aws_security_group" "gh_pages_ssh" {
  name        = "tf_gh_pages_ssh"
  description = "Allow SSH from EC2 instance connect"
  vpc_id      = aws_vpc.gh_pages_backup_site.id
}

resource "aws_vpc_security_group_ingress_rule" "EC2InstanceConnect" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  cidr_ipv4         = "18.206.107.24/29"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description = "EC2 Instance Connect"
}
resource "aws_vpc_security_group_egress_rule" "EC2InstanceConnect" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  cidr_ipv4         = "18.206.107.24/29"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description = "EC2 Instance Connect"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_egress_rule" "http" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "HttpIpv6" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_egress_rule" "HttpIpv6" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "HttpsIpv6" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv6         = "::/0"
}
resource "aws_vpc_security_group_egress_rule" "HttpsIpv6" {
  security_group_id = aws_security_group.gh_pages_ssh.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv6         = "::/0"
}

```

The last block of code is just to provision the EC2 instance. It uses the ami linked above that was created by Packer, and is associated with the subnet and security groups I created above.

```tf

#EC2 INSTANCE
resource "aws_instance" "gh-pages_backup" {
  ami           = data.hcp_packer_artifact.Gabrielc1925-github-io.external_identifier
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.gh_pages_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.gh_pages_ssh.id]
  # The two lines below this comment are for use with the data sources above to utilize prebuilt AWS VPC resources.
  # subnet_id = data.aws_subnet.public.id
  # security_groups = [data.aws_security_group.public.id]
  tags = {
    Name = "gh_pages_backup_instance"
  }
}

```

After a quick `terraform apply` my resources are provisioned and I have a working website hosted on in a EC2 instance via nginx. This basic, very low effort website is only available via http, as I did not take the time to set up a certificate to enable https.

Next would be an attempt to set up Route53 services in AWS to provide https certificates and automatic redirect for https to http. I could also look into setting up automatic failover scenarios in case the original page on github is not available at some point.

At this point, I intend to instead take a deeper look at Github Actions and to see what I can accomplish with them.
