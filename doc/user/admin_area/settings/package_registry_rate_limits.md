---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Package Registry Rate Limits **(FREE SELF)**

With the [GitLab Package Registry](../../packages/package_registry/index.md),
you can use GitLab as a private or public registry for a variety of common package managers. You can
publish and share packages, which others can consume as a dependency in downstream projects through
the [Packages API](../../../api/packages.md).

If downstream projects frequently download such dependencies, many requests are made through the
Packages API. You may therefore reach enforced [user and IP rate limits](user_and_ip_rate_limits.md).
To address this issue, you can define specific rate limits for the Packages API:

- [Unauthenticated requests (per IP)](#enable-unauthenticated-request-rate-limit-for-packages-api).
- [Authenticated API requests (per user)](#enable-authenticated-api-request-rate-limit-for-packages-api).

These limits are disabled by default.

When enabled, they supersede the general user and IP rate limits for requests to
the Packages API. You can therefore keep the general user and IP rate limits, and
increase the rate limits for the Packages API. Besides this precedence, there is
no difference in functionality compared to the general user and IP rate limits.

## Enable unauthenticated request rate limit for packages API

To enable the unauthenticated request rate limit:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > Network**, and expand **Package registry rate limits**.
1. Select **Enable unauthenticated request rate limit**.

   - Optional. Update the **Maximum unauthenticated requests per rate limit period per IP** value.
     Defaults to `800`.
   - Optional. Update the **Unauthenticated rate limit period in seconds** value.
     Defaults to `15`.

## Enable authenticated API request rate limit for packages API

To enable the authenticated API request rate limit:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > Network**, and expand **Package registry rate limits**.
1. Select **Enable authenticated API request rate limit**.

   - Optional. Update the **Maximum authenticated API requests per rate limit period per user** value.
     Defaults to `1000`.
   - Optional. Update the **Authenticated API rate limit period in seconds** value.
     Defaults to `15`.
