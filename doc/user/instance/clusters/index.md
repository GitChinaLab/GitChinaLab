---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Instance-level Kubernetes clusters (certificate-based) (DEPRECATED) **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/39840) in GitLab 11.11.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5. To connect clusters to GitLab,
use the [GitLab Agent](../../clusters/agent/index.md).

Similar to [project-level](../../project/clusters/index.md)
and [group-level](../../group/clusters/index.md) Kubernetes clusters,
instance-level Kubernetes clusters allow you to connect a Kubernetes cluster to
the GitLab instance, which enables you to use the same cluster across multiple
projects.

To view the instance level Kubernetes clusters:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Kubernetes**.

## Cluster precedence

GitLab tries to match clusters in the following order:

- Project-level clusters.
- Group-level clusters.
- Instance-level clusters.

To be selected, the cluster must be enabled and
match the [environment selector](../../../ci/environments/index.md#scope-environments-with-specs).

## Cluster environments **(PREMIUM)**

For a consolidated view of which CI [environments](../../../ci/environments/index.md)
are deployed to the Kubernetes cluster, see the documentation for
[cluster environments](../../clusters/environments.md).

## More information

For information on integrating GitLab and Kubernetes, see
[Kubernetes clusters](../../infrastructure/clusters/index.md).
