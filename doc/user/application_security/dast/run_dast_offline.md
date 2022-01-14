---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Run DAST in an offline environment **(ULTIMATE)**

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for the DAST job to
successfully run. For more information, see [Offline environments](../offline_deployments/index.md).

## Requirements for offline DAST support

To use DAST in an offline environment, you need:

- GitLab Runner with the [`docker` or `kubernetes` executor](index.md#prerequisites).
- Docker Container Registry with a locally available copy of the DAST
  [container image](https://gitlab.com/security-products/dast), found in the
  [DAST container registry](https://gitlab.com/security-products/dast/container_registry).

Note that GitLab Runner has a [default `pull policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
meaning the runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. The GitLab Runner [`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
in an offline environment if you prefer using only locally available Docker images. However, we
recommend keeping the pull policy setting to `always` if not in an offline environment, as this
enables the use of updated scanners in your CI/CD pipelines.

## Make GitLab DAST analyzer images available inside your Docker registry

For DAST, import the following default DAST analyzer image from `registry.gitlab.com` to your [local Docker container registry](../../packages/container_registry/index.md):

- `registry.gitlab.com/security-products/dast:latest`

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Please consult your IT staff to find an accepted and approved
process by which external resources can be imported or temporarily accessed.
These scanners are [periodically updated](../vulnerabilities/index.md#vulnerability-scanner-maintenance)
with new definitions, and you may be able to make occasional updates on your own.

For details on saving and transporting Docker images as a file, see Docker's documentation on
[`docker save`](https://docs.docker.com/engine/reference/commandline/save/),
[`docker load`](https://docs.docker.com/engine/reference/commandline/load/),
[`docker export`](https://docs.docker.com/engine/reference/commandline/export/), and
[`docker import`](https://docs.docker.com/engine/reference/commandline/import/).

## Set DAST CI/CD job variables to use local DAST analyzers

Add the following configuration to your `.gitlab-ci.yml` file. You must replace `image` to refer to
the DAST Docker image hosted on your local Docker container registry:

```yaml
include:
  - template: DAST.gitlab-ci.yml
dast:
  image: registry.example.com/namespace/dast:latest
```

The DAST job should now use local copies of the DAST analyzers to scan your code and generate
security reports without requiring internet access.

Alternatively, you can use the CI/CD variable `SECURE_ANALYZERS_PREFIX` to override the base registry address of the `dast` image.
