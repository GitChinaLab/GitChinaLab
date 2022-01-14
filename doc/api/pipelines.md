---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pipelines API **(FREE)**

## Pipelines pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](index.md#pagination).

## List project pipelines

> `iid` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) in GitLab 14.6.

List pipelines in a project. Child pipelines are not included in the results,
but you can [get child pipeline](pipelines.md#get-a-single-pipeline) individually.

```plaintext
GET /projects/:id/pipelines
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `scope`   | string  | no       | The scope of pipelines, one of: `running`, `pending`, `finished`, `branches`, `tags` |
| `status`  | string  | no       | The status of pipelines, one of: `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual`, `scheduled` |
| `source`  | string  | no       | In [GitLab 14.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/325439), how the pipeline was triggered, one of: `push`, `web`, `trigger`, `schedule`, `api`, `external`, `pipeline`, `chat`, `webide`, `merge_request_event`, `external_pull_request_event`, `parent_pipeline`, `ondemand_dast_scan`, or `ondemand_dast_validation`. |
| `ref`     | string  | no       | The ref of pipelines |
| `sha`     | string  | no       | The SHA of pipelines |
| `yaml_errors`| boolean  | no       | Returns pipelines with invalid configurations |
| `username`| string  | no       | The username of the user who triggered pipelines |
| `updated_after` | datetime | no | Return pipelines updated after the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before` | datetime | no | Return pipelines updated before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `order_by`| string  | no       | Order pipelines by `id`, `status`, `ref`, `updated_at` or `user_id` (default: `id`) |
| `sort`    | string  | no       | Sort pipelines in `asc` or `desc` order (default: `desc`) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines"
```

Example of response

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 1,
    "status": "pending",
    "source": "push",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "iid": 13,
    "project_id": 1,
    "status": "pending",
    "source": "web",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## Get a single pipeline

> `iid` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) in GitLab 14.6.

Get one pipeline from a project.

You can also get a single [child pipeline](../ci/pipelines/parent_child_pipelines.md).
[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36494) in GitLab 13.3.

```plaintext
GET /projects/:id/pipelines/:pipeline_id
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

Example of response

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "success",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": 123.65,
  "queued_duration": 0.010,
  "coverage": "30.0",
  "web_url": "https://example.com/foo/bar/pipelines/46"
}
```

### Get variables of a pipeline

```plaintext
GET /projects/:id/pipelines/:pipeline_id/variables
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/variables"
```

Example of response

```json
[
  {
    "key": "RUN_NIGHTLY_BUILD",
    "variable_type": "env_var",
    "value": "true"
  },
  {
    "key": "foo",
    "value": "bar"
  }
]
```

### Get a pipeline's test report

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202525) in GitLab 13.0.

NOTE:
This API route is part of the [Unit test report](../ci/unit_test_reports.md) feature.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

Sample request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report"
```

Sample response:

```json
{
  "total_time": 5,
  "total_count": 1,
  "success_count": 1,
  "failed_count": 0,
  "skipped_count": 0,
  "error_count": 0,
  "test_suites": [
    {
      "name": "Secure",
      "total_time": 5,
      "total_count": 1,
      "success_count": 1,
      "failed_count": 0,
      "skipped_count": 0,
      "error_count": 0,
      "test_cases": [
        {
          "status": "success",
          "name": "Security Reports can create an auto-remediation MR",
          "classname": "vulnerability_management_spec",
          "execution_time": 5,
          "system_output": null,
          "stack_trace": null
        }
      ]
    }
  ]
}
```

### Get a pipeline's test report summary

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65471) in GitLab 14.2.

NOTE:
This API route is part of the [Unit test report](../ci/unit_test_reports.md) feature.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report_summary
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

Sample request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report_summary"
```

Sample response:

```json
{
    "total": {
        "time": 1904,
        "count": 3363,
        "success": 3351,
        "failed": 0,
        "skipped": 12,
        "error": 0,
        "suite_error": null
    },
    "test_suites": [
        {
            "name": "test",
            "total_time": 1904,
            "total_count": 3363,
            "success_count": 3351,
            "failed_count": 0,
            "skipped_count": 12,
            "error_count": 0,
            "build_ids": [
                66004
            ],
            "suite_error": null
        }
    ]
}
```

## Create a new pipeline

> `iid` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) in GitLab 14.6.

```plaintext
POST /projects/:id/pipeline
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `ref`       | string  | yes      | Reference to commit |
| `variables` | array   | no       | An array containing the variables available in the pipeline, matching the structure `[{ 'key': 'UPLOAD_TO_S3', 'variable_type': 'file', 'value': 'true' }, {'key': 'TEST', 'value': 'test variable'}]`. If `variable_type` is excluded, it defaults to `env_var`. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main"
```

Example of response

```json
{
  "id": 61,
  "iid": 21,
  "project_id": 1,
  "sha": "384c444e840a515b23f21915ee5766b87068a70d",
  "ref": "main",
  "status": "pending",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-11-04T09:36:13.747Z",
  "updated_at": "2016-11-04T09:36:13.977Z",
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/61"
}
```

## Retry jobs in a pipeline

> `iid` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) in GitLab 14.6.

```plaintext
POST /projects/:id/pipelines/:pipeline_id/retry
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes   | The ID of a pipeline |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/retry"
```

Response:

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "pending",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46"
}
```

## Cancel a pipeline's jobs

```plaintext
POST /projects/:id/pipelines/:pipeline_id/cancel
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes   | The ID of a pipeline |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/cancel"
```

Response:

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "canceled",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46"
}
```

## Delete a pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22988) in GitLab 11.6.

```plaintext
DELETE /projects/:id/pipelines/:pipeline_id
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request "DELETE" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```
