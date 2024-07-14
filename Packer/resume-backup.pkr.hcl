packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3.2"
    }
    git = {
      version = ">= 0.6.3"
      source  = "github.com/ethanmdavidson/git"
    }
    ansible = {
      version = "~> 1.1.1"
      source  = "github.com/hashicorp/ansible"
    }
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}
