---
layout: page
title: HRIA Masjid Website Svelte
description: Relaunch of the HRIA Masjid website using Sveltekit
img: assets/img/HRIA_Website_diagram_close.png
importance: 2
category: work
related_publications: false
toc:
  sidebar: left
---

## Introduction

As the original project went on hiatus, I decided to take the opportunity to learn Sveltekit and relaunch the website using that framework. This new website is a work in progress, but I wanted to document what I have done so far.  
The goal is to create a modular website that can be easily customized and deployed for a different masjid with minimal effort. I am builiding it in a way that will allow for future expansion and customization options for the masjid.
The current stack includes:

  - Sveltekit for the base frontend and backend framework
  - Supabase running Postgres to serve as the database layer
  - Drizzle ORM to handle communication between the Sveltekit app and the Postgres database
  - Tailwind CSS for styling
  - Ansible for provisioning of a development environment for easy adoption by devs who wish to contribute to the project

### Link to the project

[github.com/three-knots/HRIA_Website](https://github.com/three-knots/HRIA_Website)

---

## Why Sveltekit?

I chose to use Sveltekit for a few reasons. First, I wanted to learn a new framework, and Sveltekit is one of the newer ones on the block. Second, I wanted to try and build a website that would be easier to maintain and extend in the future, and Sveltekit seems to be a good choice for that.  Third, I wanted to try and build a website that would be more secure, and Sveltekit has a good reputation in that area.
Additionally, I want to be able to use a very lightweight framework that doesn't require a lot of heavy lifting from the server to deliver the website to the user. This will allow me to focus on other areas of the project that need attention.
I want something fast, but also able to handle complicated interactions so that I can implement features like tool sharing, group event scheduling, chat, and more.

## Why Supabase?

Supabase is a relatively new player in the database space, but it has a lot of potential. It is built on Postgres, so it inherits a lot of the strengths of that database system. It also has a lot of additional features that make it easier to develop and manage a database layer. I am using the PostgresSQL version, but there is also a Realtime version that includes a lot of functionality for building collaborative applications. 

## Branching methodology

I chose to stick with the trunk-based branching methodology as we had planned for the [original project](https://gabrielc1925.github.io/projects/HR-masjid/). I have not yet implemented a staging branch or any rigorous testing, as I am still in the early stages of development, but I plan to add those in soon.

## Local Development Environment

I have struggled with getting a containerized development environment working, as the setup and configuration of the database alongside the application has been difficult. I have instead set up an ansible playbook that will setup all the dependencies locally to allow for a quick start to development. This is not a perfect solution, but it is a step in the right direction.

## Website Features

Lots of features are planned, and the goal is to make a website that is modular. If a small masjid wants a basic page, they can just go with the base package. This will keep costs low and reduce the barrier for entry. If they grow and want to expand their offerings, then they can choose to enable a feature and have that prebuilt add-on generate for them. In some cases. this will require them to pay for more compute and/or storage space on whatever cloud provider they are using. We will have to work out the break points and create a guide for that side of things as well.
We want to be able to be easily started by small masjids, but also provide long term features for larger communities who have good engagement and want more support without having to branch out into a different service.

## Internal Workflow Improvements

Lots of thoughts have been kicked around here about how to integrate different services in an efficient but non-intrusive way, and how to structure out the Jira cards so that they are more readable and clear. Nothing concrete has been acted on yet though.
