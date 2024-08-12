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

build {
  # HCP Packer settings
  hcp_packer_registry {
    bucket_name = "Gabrielc1925-github-io"
    description = <<EOT
This is an image for a backup of the github pages site for gabrielc1925
    EOT

  bucket_labels = {
      "GitHub-Pages" = "learn-packer-github-actions",
    }
  }

  sources = [
    "source.amazon-ebs.github-pages",
  ]

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

  post-processor "manifest" {
    output     = "packer_manifest.json"
    strip_path = true
    custom_data = {
      version_fingerprint = packer.versionFingerprint
    }
  }
}