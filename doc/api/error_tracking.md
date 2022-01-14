---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Error Tracking settings API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34940) in GitLab 12.7.

## Error Tracking project settings

The project settings API allows you to retrieve the [Error Tracking](../operations/error_tracking.md)
settings for a project. Only for users with [Maintainer role](../user/permissions.md) for the project.

### Get Error Tracking settings

```plaintext
GET /projects/:id/error_tracking/settings
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings"
```

Example response:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

### Enable or disable the Error Tracking project settings

The API allows you to enable or disable the Error Tracking settings for a project. Only for users with the
[Maintainer role](../user/permissions.md) for the project.

```plaintext
PATCH /projects/:id/error_tracking/settings
```

| Attribute    | Type    | Required | Description           |
| ------------ | ------- | -------- | --------------------- |
| `id`         | integer | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `active`     | boolean | yes      | Pass `true` to enable the already configured error tracking settings or `false` to disable it. |
| `integrated` | boolean | no       | Pass `true` to enable the integrated error tracking backend. [Available in](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68260) GitLab 14.2 and later. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true"
```

Example response:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

## Error Tracking client keys

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68384) in GitLab 14.3.

For [integrated error tracking](https://gitlab.com/gitlab-org/gitlab/-/issues/329596) feature. Only for users with the
[Maintainer role](../user/permissions.md) for the project.

### List project client keys

```plaintext
GET /projects/:id/error_tracking/client_keys
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "active": true,
    "public_key": "glet_aa77551d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@gitlab.example.com/api/v4/error_tracking/collector/5"
  },
  {
    "id": 3,
    "active": true,
    "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_0ff98b1d849c083f76d0bc545ed053a3@gitlab.example.com/api/v4/error_tracking/collector/5"
  }
]
```

### Create a client key

Creates a new client key for a project. The public key attribute is generated automatically.

```plaintext
POST /projects/:id/error_tracking/client_keys
```

| Attribute  | Type | Required | Description |
| ---------  | ---- | -------- | ----------- |
| `id`       | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

Example response:

```json
{
  "id": 3,
  "active": true,
  "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
  "sentry_dsn": "https://glet_0ff98b1d849c083f76d0bc545ed053a3@gitlab.example.com/api/v4/error_tracking/collector/5"
}
```

### Delete a client key

Removes a client key from the project.

```plaintext
DELETE /projects/:id/error_tracking/client_keys/:key_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `key_id`  | integer | yes | The ID of the client key. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys/13"
```
