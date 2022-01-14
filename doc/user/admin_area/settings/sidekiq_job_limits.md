---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Sidekiq job size limits **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68982) in GitLab 14.3.

[Sidekiq](../../../administration/sidekiq.md) jobs get stored in
Redis. To avoid excessive memory for Redis, we:

- Compress job arguments before storing them in Redis.
- Reject jobs that exceed the specified threshold limit after compression.

To access Sidekiq job size limits:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Sidekiq job size limits**.
1. Adjust the compression threshold or size limit. The compression can
   be disabled by selecting the **Track** mode.

## Available settings

| Setting                                   | Default          | Description                                                                                                                                                                   |
|-------------------------------------------|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Limiting mode                             | Compress         | This mode compresses the jobs at the specified threshold and rejects them if they exceed the specified limit after compression.                                               |
| Sidekiq job compression threshold (bytes) | 100 000 (100 KB) | When the size of arguments exceeds this threshold, they are compressed before being stored in Redis.                                                                          |
| Sidekiq job size limit (bytes)            | 0                | The jobs exceeding this size after compression are rejected. This avoids excessive memory usage in Redis leading to instability. Setting it to 0 prevents rejecting jobs.     |

After changing these values, [restart Sidekiq](../../../administration/restart_gitlab.md).
