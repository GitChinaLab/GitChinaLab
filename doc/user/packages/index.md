---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Packages and Registries **(FREE)**

The GitLab [Package Registry](package_registry/index.md) acts as a private or public registry
for a variety of common package managers. You can publish and share
packages, which can be easily consumed as a dependency in downstream projects.

## Container Registry

The GitLab [Container Registry](container_registry/index.md) is a secure and private registry for container images. It's built on open source software and completely integrated within GitLab. Use GitLab CI/CD to create and publish images. Use the GitLab [API](../../api/container_registry.md) to manage the registry across groups and projects.

## Infrastructure Registry

The GitLab [Infrastructure Registry](infrastructure_registry/index.md) is a secure and private registry for infrastructure packages. You can use GitLab CI/CD to create and publish infrastructure packages.

The Infrastructure Registry supports the following formats:

| Package type | GitLab version |
| ------------ | -------------- |
| [Terraform Module](terraform_module_registry/index.md) | 14.0+ |

## Dependency Proxy

The [Dependency Proxy](dependency_proxy/index.md) is a local proxy for frequently-used upstream images and packages.
