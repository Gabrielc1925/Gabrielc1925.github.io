---
layout: page
title: Highlands Ranch Masjid Collaboration
description: Work with a team to create containerized website solution
img: assets/img/HR-masjid-orgChart.jpg
importance: 1
category: personal
related_publications: false
toc:
  sidebar: left
---

## Introduction

This was a project to create a containerized website solution for one mosque, but one that could be easily customized and deployed for a different website by anyone with a very small amount of tech knowledge.

This was a collaboration between several people, so that we could all get some low-risk practice and have the opportunity to add this to our portfolios. There were two people on the Dev team, two people working from a DevOps perspective, and one project manager who would help to guide and shape the project and help out where needed.

We began with several brainstorming sessions, and then began meeting over Slack to hammer out a project framework. We used Jira for project managment, utilizing a kanban framework to organize our goals and progress. Our primary Epics (large initial goals) to start were to Define SDLC for Lower Environments, Create Features for Website, and to Improve Internal Workflow.

The project eventually was put on hiatus as we all got busy with work and other things, but I want to document what we achieved so far, so that I have a framework to build on when we resume working on it.

## Define SDLC for Lower Environments

From a DevOps perspective, defining a Software Development Life Cycle is extremely important. Having a plan in place for how things are done makes it easier to prevent issues, and to track and resolve them when they occur. It also makes it easier for the devs, as they have a verified way to test their code locally to discover any issues before it is pushed to the repo. Every step of the way, there is additional testing that can be done to ensure that as many bugs as possible are found before the product goes to production.

We chose to go with a branching methodology, with standardized naming based on the Jira title. After a feature was ready to be pushed to main, and other testing had been done locally, we would test in a dedicated environment mirroring the live site. All updates would first have to go through a pull request to the staging branch, which we would have a hosted DNS for. This way, we could do dedicated testing in a live environment, without affecting the production branch.

## Website Features

placeholder

## Internal Workflow Improvements

placeholder
