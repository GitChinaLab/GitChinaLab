---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Prepare Auto DevOps for deployment **(FREE)**

If you enable Auto DevOps without setting the base domain and deployment
strategy, GitLab can't deploy your application directly. Therefore, we
recommend that you prepare them before enabling Auto DevOps.

## Deployment strategy

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/38542) in GitLab 11.0.

When using Auto DevOps to deploy your applications, choose the
[continuous deployment strategy](../../ci/introduction/index.md)
that works best for your needs:

| Deployment strategy | Setup | Methodology |
|--|--|--|
| **Continuous deployment to production** | Enables [Auto Deploy](stages.md#auto-deploy) with the default branch continuously deployed to production. | Continuous deployment to production.|
| **Continuous deployment to production using timed incremental rollout** | Sets the [`INCREMENTAL_ROLLOUT_MODE`](customize.md#timed-incremental-rollout-to-production) variable to `timed`. | Continuously deploy to production with a 5 minutes delay between rollouts. |
| **Automatic deployment to staging, manual deployment to production** | Sets [`STAGING_ENABLED`](customize.md#deploy-policy-for-staging-and-production-environments) to `1` and [`INCREMENTAL_ROLLOUT_MODE`](customize.md#incremental-rollout-to-production) to `manual`. | The default branch is continuously deployed to staging and continuously delivered to production. |

You can choose the deployment method when enabling Auto DevOps or later:

1. In GitLab, go to your project's **Settings > CI/CD > Auto DevOps**.
1. Choose the deployment strategy.
1. Select **Save changes**.

NOTE:
Use the [blue-green deployment](../../ci/environments/incremental_rollouts.md#blue-green-deployment) technique
to minimize downtime and risk.

## Auto DevOps base domain

The Auto DevOps base domain is required to use
[Auto Review Apps](stages.md#auto-review-apps), [Auto Deploy](stages.md#auto-deploy), and
[Auto Monitoring](stages.md#auto-monitoring).

To define the base domain, either:

- In the project, group, or instance level: go to your cluster settings and add it there.
- In the project or group level: add it as an environment variable: `KUBE_INGRESS_BASE_DOMAIN`.
- In the instance level: go to **Menu > Admin > Settings > CI/CD > Continuous Integration and Delivery** and add it there.

The base domain variable `KUBE_INGRESS_BASE_DOMAIN` follows the same order of precedence
as other environment [variables](../../ci/variables/index.md#cicd-variable-precedence).

If you don't specify the base domain in your projects and groups, Auto DevOps uses the instance-wide **Auto DevOps domain**.

Auto DevOps requires a wildcard DNS A record matching the base domain(s). For
a base domain of `example.com`, you'd need a DNS entry like:

```plaintext
*.example.com   3600     A     1.2.3.4
```

In this case, the deployed applications are served from `example.com`, and `1.2.3.4`
is the IP address of your load balancer, generally NGINX ([see requirements](requirements.md)).
Setting up the DNS record is beyond the scope of this document; check with your
DNS provider for information.

Alternatively, you can use free public services like [nip.io](https://nip.io)
which provide automatic wildcard DNS without any configuration. For [nip.io](https://nip.io),
set the Auto DevOps base domain to `1.2.3.4.nip.io`.

After completing setup, all requests hit the load balancer, which routes requests
to the Kubernetes pods running your application.
