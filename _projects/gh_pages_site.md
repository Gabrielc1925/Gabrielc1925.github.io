---
layout: page
title: CI/CD Project
description: Automate Provisioning and Deployment of Resources
img: assets/img/ghpages-project-diagram.jpg
importance: 1
category: work
related_publications: false
toc:
  sidebar: left
---

## Project Overview

<div class="row">
<div class="col-sm mt-3 mt-md-0">
{% include figure.liquid loading="eager" path="assets/img/ghpages-project-diagram.jpg" title="GH-Pages Project Diagram" class="img-fluid rounded z-depth-1" %}
</div>
</div>
<div class="caption">
Diagram of the various steps of this project.
</div>

This project began as a way to build an online resume and portfolio, so that I could organize information about myself in a manner that is visually pleasing and easy to navigate.

This was a learning experience in and of itself, as I had to learn how to format lists in Javascript and YAML, how to read and navigate Liquid, CSS, and HTML files, how to write in Markdown, and how to read and modify GitHub Actions files.

As time went on, I needed source files to use for practice with Ansible and Terraform. This already created page provided exactly what I needed, which is why it is used throughout the projects.

This page will just be a diagram of the project with a brief explanation of each step. You can click on the link for each page to be taken to a more detailed walkthrough of the code for each step.

---

## Deploment to Github Pages with Jekyll

<div class="row">
<div class="col-sm mt-3 mt-md-0">
{% include figure.liquid loading="eager" path="assets/img/github-pages-project.jpg" title="Github pages with jekyll" class="img-fluid rounded z-depth-1" %}
</div>
</div>
<div class="caption">
Jekyll did all the work.
</div>

I used a prebuilt template called [al-folio](https://github.com/alshedivat/al-folio) for the page. It gave me a beautiful and well-thought out design with support for code, images, and many other features that I might use in the future.

I cloned the template to [my Github repo](https://github.com/Gabrielc1925/Gabrielc1925.github.io) and began to customize the files that were provided.

I learned Markdown for this, and had to re-learn how to write in YAML to fill out some of the backup lists. I also had to learn basic javascript notation in order to fill out the tables to populate my CV/Resume page.

I then learned how to read and modify GitHub Actions workflow files and the output associated with them running. I removed many of the template workflows as they were not needed for my development environment, and I modified the others as needed. I did mess around with writing and adding GitHub Actions workflows, but there was nothing that was pressing enough that I kept it long term - I preferred to work on the other parts of this project for now.

---

## AMI Creation with Packer using Ansible

<div class="row">
<div class="col-sm mt-3 mt-md-0">
{% include figure.liquid loading="eager" path="assets/img/packer-ansible-project.jpg" title="Packer and Ansible diagram" class="img-fluid rounded z-depth-1" %}
</div>
</div>
<div class="caption">
Using Ansible to provision an AMI for Packer to create and store.
</div>

[Using Packer to create an Amazon Machine Image](https://gabrielc1925.github.io/projects/packer_aws_backup/) was my next goal to work towards. This would mean that I have a prebuilt copy of my website ready to deploy in minutes in case of the site being down or some other disaster.  
I could then use this further to practice with automated provisioning via Terraform, automated disaster recovery, or containerization with Docker and moving to Kubernetes, ECS or EKS.

I had used Ansible previously about a year ago, but needed a refresher on how to write playbooks. I ended up learning much more than I initially expected I needed to learn, as I was using Ansible locally previously rather than interacting with a cloud provider through third-party modules.

One major problem for me was that I misunderstood how Ansible interacted with file creation and naming. I was copying parts of a git repo to the project, and then moving certain files from the local repo to where they needed to live long-term. I was referencing files that did not exist, so they were not getting copied to where they should belong - and then the site was not behaving as expected. I eventually figured out how to use Packer's debug mode to keep the created AMI open so that I could SSH into it andfigure out where the files were. This allowed me to correct the name I was referencing, and get everything working properly.

---

## Provisioning Resources with Terraform

<div class="row">
<div class="col-sm mt-3 mt-md-0">
{% include figure.liquid loading="eager" path="assets/img/terraform-deploy-project.jpg" title="Terraform deployment" class="img-fluid rounded z-depth-1" %}
</div>
</div>
<div class="caption">
Using Terraform to create and manage resources in AWS.
</div>

I decided that my next goal would be to [practice using Terraform to provision resources in AWS](https://gabrielc1925.github.io/projects/terraform_aws/), including everything needed to run the site. I used the AMI to create an EC2 Instance, and then provisioned all the parts of a VPC that were needed to allow people to access the site from a public IP address.

This brought a number of hurdles that I had to learn from and overcome. As my understanding of the documentation progressed, I re-wrote the code several times to ensure that my formatting was correct and the created product performed as expected.

My biggest problem came from understanding how to write security group rules. I could not figure out how to format the listing for which ports I wanted to open.  
I made a security group on AWS and just redirected my VPS to utilize the prebuilt security group instead, so that I could go forward with troubleshooting the other parts of the deployed resources. Eventually, I realized that the cidr block argument was looking for a string within double quotation marks (e.g."{string}"), and I was formatting the cidr block incorrectly for ipv4, using ipv6 cider block naming convention. I was able to get the security group settings working using this information.

---

## Next Steps

I have not decided where to take this project yet, as I have several other projects I am currently working on.

Other things that could be done though would be to set up monitoring software, automated failover to AWS, HTTPS/DNS management, code security testing workflows, and digging deeper into GitHub Actions to see what else I can accomplish with it that may be beneficial.
