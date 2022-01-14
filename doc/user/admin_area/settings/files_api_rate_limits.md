---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Files API rate limits **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68561) in GitLab 14.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75918) in GitLab 14.6. [Feature flag files_api_throttling](https://gitlab.com/gitlab-org/gitlab/-/issues/338903) removed.

The [Repository files API](../../../api/repository_files.md) enables you to
fetch, create, update, and delete files in your repository. To improve the security
and durability of your web application, you can enforce
[rate limits](../../../security/rate_limits.md) on this API. Any rate limits you
create for the Files API override the [general user and IP rate limits](user_and_ip_rate_limits.md).

## Define Files API rate limits

Rate limits for the Files API are disabled by default. When enabled, they supersede
the general user and IP rate limits for requests to the
[Repository files API](../../../api/repository_files.md). You can keep any general user
and IP rate limits already in place, and increase or decrease the rate limits
for the Files API. No other new features are provided by this override.

Prerequisite:

- You must have the Administrator role for your instance.

To override the general user and IP rate limits for requests to the Repository files API:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Files API Rate Limits**.
1. Select the check boxes for the types of rate limits you want to enable:
   - **Unauthenticated API request rate limit**
   - **Authenticated API request rate limit**
1. _If you enabled unauthenticated API request rate limits:_
   1. Select the **Max unauthenticated API requests per period per IP**.
   1. Select the **Unauthenticated API rate limit period in seconds**.
1. _If you enabled authenticated API request rate limits:_
   1. Select the **Max authenticated API requests per period per user**.
   1. Select the **Authenticated API rate limit period in seconds**.

## Related topics

- [Rate limits](../../../security/rate_limits.md)
- [Repository files API](../../../api/repository_files.md)
- [User and IP rate limits](user_and_ip_rate_limits.md)
