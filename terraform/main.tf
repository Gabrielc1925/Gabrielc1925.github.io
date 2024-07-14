terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.58.0"
        }
    }
}
provider "aws" {
    region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "???" {
    cidr_block = "10.0.0.0/16" #todo 
}


# Configure EC2
resource "aws_instance" "app server" {
    ami     = "ami-0b72821e2f351e396"
    instance_type = "t2.micro"
    
    tags = {
        Name = "ResumeWebsiteAutoBackup"
    }
}
