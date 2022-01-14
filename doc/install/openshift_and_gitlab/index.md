---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# OpenShift support

OpenShift - GitLab compatibility can be addressed in three different aspects. This page helps navigating between these aspects and provides introductory information for getting started with OpenShift and GitLab.

## What is OpenShift

OpenShift helps you to develop, deploy, and manage container-based applications. It provides you with a self-service platform to create, modify, and deploy applications on demand, thus enabling faster development and release life cycles.

## Use OpenShift to run GitLab Self-Managed

Running GitLab within an OpenShift cluster is officially supported using the GitLab Operator. You can learn more on
[setting up GitLab on OpenShift on the GitLab Operator's documentation](https://docs.gitlab.com/charts/installation/operator.html).
Some components (documented on the GitLab Operator doc) are not supported yet.

## Deploy to and integrate with OpenShift from GitLab

Deploying custom or COTS applications on top of OpenShift from GitLab is supported using [the GitLab Agent](../../user/clusters/agent/index.md).

## Use OpenShift to run a GitLab Runner Fleet

The GitLab Operator does not include the GitLab Runner. To install and manage a GitLab Runner fleet in an OpenShift cluster, use the
[GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator).

## Unsupported GitLab features

### Docker-in-Docker

When using OpenShift to run a GitLab Runner Fleet, we do not support some GitLab features given OpenShift's security model.
Features requiring Docker-in-Docker might not work.

For Auto DevOps, the following features are not supported yet:

- Auto Code Quality
- Auto License Compliance
- Auto Browser Performance Testing
- Auto Build

For Auto Build, there's a [possible workaround using `kaniko`](../../ci/docker/using_kaniko.md).
You can check the progress of the implementation in this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/332560).
