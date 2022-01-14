---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Cluster Environments (DEPRECATED) **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13392) in GitLab 12.3 for group-level clusters.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14809) in GitLab 12.4 for instance-level clusters.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

Cluster environments provide a consolidated view of which CI [environments](../../ci/environments/index.md) are
deployed to the Kubernetes cluster and it:

- Shows the project and the relevant environment related to the deployment.
- Displays the status of the pods for that environment.

## Overview

With cluster environments, you can gain insight into:

- Which projects are deployed to the cluster.
- How many pods are in use for each project's environment.
- The CI job that was used to deploy to that environment.

![Cluster environments page](img/cluster_environments_table_v12_3.png)

Access to cluster environments is restricted to [group maintainers and
owners](../permissions.md#group-members-permissions)

## Usage

In order to:

- Track environments for the cluster, you must
  [deploy to a Kubernetes cluster](../project/clusters/deploy_to_cluster.md)
  successfully.
- Show pod usage correctly, you must
  [enable deploy boards](../project/deploy_boards.md#enabling-deploy-boards).

After you have successful deployments to your group-level or instance-level cluster:

1. Navigate to your group's **Kubernetes** page.
1. Click on the **Environments** tab.

Only successful deployments to the cluster are included in this page.
Non-cluster environments aren't included.
