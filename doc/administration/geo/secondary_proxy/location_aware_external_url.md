---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Location-aware public URL **(PREMIUM SELF)**

With [Geo proxying for secondary sites](index.md), you can provide GitLab users
with a single URL that automatically uses the Geo site closest to them.
Users don't need to use different URLs or worry about read-only operations to take
advantage of closer Geo sites as they move.

With [Geo proxying for secondary sites](index.md) web and Git requests are proxied
from **secondary** sites to the **primary**.

Though these instructions use [AWS Route53](https://aws.amazon.com/route53/),
other services such as [Cloudflare](https://www.cloudflare.com/) can be used
as well.

## Prerequisites

This example creates a `gitlab.example.com` subdomain that automatically directs
requests:

- From Europe to a **secondary** site.
- From all other locations to the **primary** site.

The URLs to access each node by itself are:

- `primary.example.com` as a Geo **primary** site.
- `secondary.example.com` as a Geo **secondary** site.

For this example, you need:

- A working GitLab **primary** site that is accessible at `gitlab.example.com` _and_ `primary.example.com`.
- A working GitLab **secondary** site.
- A Route53 Hosted Zone managing your domain for the Route53 setup.

If you haven't yet set up a Geo _primary_ site and _secondary_ site, see the
[Geo setup instructions](../index.md#setup-instructions).

## AWS Route53

### Create a traffic policy

In a Route53 Hosted Zone, traffic policies can be used to set up a variety of
routing configurations.

1. Go to the
[Route53 dashboard](https://console.aws.amazon.com/route53/home) and select
**Traffic policies**.

1. Select **Create traffic policy**.
1. Fill in the **Policy Name** field with `Single Git Host` and select **Next**.
1. Leave **DNS type** as `A: IP Address in IPv4 format`.
1. Select **Connect to...**, then **Geolocation rule**.
1. For the first **Location**:
   1. Leave it as `Default`.
   1. Select **Connect to...**, then **New endpoint**.
   1. Choose **Type** `value` and fill it in with `<your **primary** IP address>`.

1. For the second **Location**:
   1. Choose `Europe`.
   1. Select **Connect to...** and select **New endpoint**.
   1. Choose **Type** `value` and fill it in with `<your **secondary** IP address>`.

   ![Add traffic policy endpoints](img/single_url_add_traffic_policy_endpoints.png)

1. Select **Create traffic policy**.
1. Fill in **Policy record DNS name** with `gitlab`.

   ![Create policy records with traffic policy](img/single_url_create_policy_records_with_traffic_policy.png)

1. Select **Create policy records**.

You have successfully set up a single host, like `gitlab.example.com`, which
distributes traffic to your Geo sites by geolocation.

## Enable Geo proxying for secondary sites

After setting up a single URL to use for all Geo sites, continue with the [steps to enable Geo proxying for secondary sites](index.md).
