---
layout: page
title: Highlands Ranch Masjid Collaboration
description: Work with a team to create containerized website solution
img: assets/img/HR-masjid-orgChart.jpg
importance: 3
category: work
related_publications: false
toc:
  sidebar: left
---

## Introduction

This was a project to create a containerized website solution for one mosque, but one that could be easily customized and deployed for a different website by anyone with a very small amount of tech knowledge.

This was a collaboration between several people, so that we could all get some low-risk practice and have the opportunity to add this to our portfolios. There were two people on the Dev team, two people working from a DevOps perspective, and one project manager who would help to guide and shape the project and help out where needed.

We began with several brainstorming sessions, and then began meeting over Slack to hammer out a project framework. We used Jira for project management, utilizing a Kanban framework to organize our goals and progress. Our primary Epics (large initial goals) to start were to Define SDLC for Lower Environments, Create Features for Website, and to Improve Internal Workflow.

The project eventually was put on hiatus as we all got busy with work and other things, but I want to document what we achieved so far, so that I have a framework to build on when we resume working on it.

## Define SDLC for Lower Environments

From a DevOps perspective, defining a Software Development Life Cycle is extremely important. Having a plan in place for how things are done makes it easier to prevent issues, and to track and resolve them when they occur. It also makes it easier for the devs, as they have a verified way to test their code locally to discover any issues before it is pushed to the repo. Every step of the way, there is additional testing that can be done to ensure that as many bugs as possible are found before the product goes to production.

### Branching methodology

We chose to go with a trunk-based branching methodology with standardized naming based on the Jira title. After a feature was ready to be pushed to main, and other testing had been done locally, we would test in a dedicated environment mirroring the live site. All updates would first have to go through a pull request to the staging branch, which we would have a hosted DNS for. This way, we could do dedicated testing in a live environment, without affecting the production branch.

### Local Development Environment

So far we have created a testing environment where you can run docker compose from the project files directory and it will build a local version of the website to test feature changes. This was documented with an instructional page, but it is currently based off of someone else's docker image and we will want to create our own docker image from scratch eventually.  
Long-term, we really need to have a complete development environment solution so that the devs can join and have immediate access to all the resources that they need for building and testing. We want this standardized to ensure that it is repeatable and doesn't require following an extended series of instructions every time they want to pick up a piece of the project.

## Website Features

Lots of features are planned, and the goal is to make a website that is modular. If a small masjid wants a basic page, they can just go with the base package. This will keep costs low and reduce the barrier for entry. If they grow and want to expand their offerings, then they can choose to enable a feature and have that prebuilt add-on generate for them. In some cases. this will require them to pay for more compute and/or storage space on whatever cloud provider they are using. We will have to work out the break points and create a guide for that side of things as well.
We want to be able to be easily started by small masjids, but also provide long term features for larger communities who have good engagement and want more support without having to branch out into a different service.

## Internal Workflow Improvements

Lots of thoughts have been kicked around here about how to integrate different services in an efficient but non-intrusive way, and how to structure out the Jira cards so that they are more readable and clear. Nothing concrete has been acted on yet though.
