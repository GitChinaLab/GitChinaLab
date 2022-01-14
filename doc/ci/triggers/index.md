---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: tutorial
---

# Trigger pipelines by using the API **(FREE)**

To trigger a pipeline for a specific branch or tag, you can use an API call
to the [pipeline triggers API endpoint](../../api/pipeline_triggers.md).

When authenticating with the API, you can use:

- A [trigger token](#create-a-trigger-token) to trigger a branch or tag pipeline.
- A [CI/CD job token](../jobs/ci_job_token.md) to trigger a [multi-project pipeline](../pipelines/multi_project_pipelines.md#create-multi-project-pipelines-by-using-the-api).

## Create a trigger token

You can trigger a pipeline for a branch or tag by generating a trigger token and using it
to authenticate an API call. The token impersonates a user's project access and permissions.

Prerequisite:

- You must have at least the [Maintainer role](../../user/permissions.md) for the project.

To create a trigger token:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Pipeline triggers**.
1. Enter a description and select **Add trigger**.
   - You can view and copy the full token for all triggers you have created.
   - You can only see the first 4 characters for tokens created by other project members.

WARNING:
It is a security risk to save tokens in plain text in public projects. Potential
attackers could use a trigger token exposed in the `.gitlab-ci.yml` file to impersonate
the user that created the token. Use [masked CI/CD variables](../variables/index.md#mask-a-cicd-variable)
to improve the security of trigger tokens.

## Trigger a pipeline

After you [create a trigger token](#create-a-trigger-token), you can use it to trigger
pipelines with a tool that can access the API, or a webhook.

### Use cURL

You can use cURL to trigger pipelines with the [pipeline triggers API endpoint](../../api/pipeline_triggers.md).
For example:

- Use a multiline cURL command:

  ```shell
  curl --request POST \
       --form token=<token> \
       --formref=<ref_name> \
       "https://gitlab.example.com/api/v4/projects/<project_id>/trigger/pipeline"
  ```

- Use cURL and pass the `<token>` and `<ref_name>` in the query string:

  ```shell
  curl --request POST \
      "https://gitlab.example.com/api/v4/projects/<project_id>/trigger/pipeline?token=<token>&ref=<ref_name>"
  ```

In each example, replace:

- The URL with `https://gitlab.com` or the URL of your instance.
- `<token>` with your trigger token.
- `<ref_name>` with a branch or tag name, like `main`.
- `<project_id>` with your project ID, like `123456`. The project ID is displayed
  at the top of every project's landing page.

### Use a CI/CD job

You can use a CI/CD job with a triggers token to trigger pipelines when another pipeline
runs.

For example, to trigger a pipeline on the `main` branch of `project-B` when a tag
is created in `project-A`, add the following job to project A's `.gitlab-ci.yml` file:

```yaml
trigger_pipeline:
  stage: deploy
  script:
    - 'curl --fail --request POST --form token=$MY_TRIGGER_TOKEN --form ref=main "https://gitlab.example.com/api/v4/projects/123456/trigger/pipeline"'
  rules:
    - if: $CI_COMMIT_TAG
```

In this example:

- `1234` is the project ID for `project-B`. The project ID is displayed at the top
  of every project's landing page.
- The [`rules`](../yaml/index.md#rules) cause the job to run every time a tag is added to `project-A`.
- `MY_TRIGGER_TOKEN` is a [masked CI/CD variables](../variables/index.md#mask-a-cicd-variable)
  that contains the trigger token.

### Use a webhook

To trigger a pipeline from another project's webhook, use a webhook URL like the following
for push and tag events:

```plaintext
https://gitlab.example.com/api/v4/projects/9/ref/main/trigger/pipeline?token=TOKEN
```

Replace:

- The URL with `https://gitlab.com` or the URL of your instance.
- `<token>` with your trigger token.
- `<ref_name>` with a branch or tag name, like `main`.
- `<project_id>` with your project ID, like `123456`. The project ID is displayed
  at the top of the project's landing page.

The `ref` in the URL takes precedence over the `ref` in the webhook payload. The
payload `ref` is the branch that fired the trigger in the source repository.
You must URL-encode `ref` if it contains slashes.

#### Use a webhook payload

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31197) in GitLab 13.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/321027) in GitLab 13.11.

If you trigger a pipeline by using a webhook, you can access the webhook payload with
the `TRIGGER_PAYLOAD` [predefined CI/CD variable](../variables/predefined_variables.md).
The payload is exposed as a [file-type variable](../variables/index.md#cicd-variable-types),
so you can access the data with `cat $TRIGGER_PAYLOAD` or a similar command.

### Pass CI/CD variables in the API call

You can pass any number of [CI/CD variables](../variables/index.md) in the trigger API call.
These variables have the [highest precedence](../variables/index.md#cicd-variable-precedence),
and override all variables with the same name.

The parameter is of the form `variables[key]=value`, for example:

```shell
curl --request POST \
  --form token=TOKEN \
  --form ref=main \
  --form "variables[UPLOAD_TO_S3]=true" \
  "https://gitlab.example.com/api/v4/projects/123456/trigger/pipeline"
```

CI/CD variables in triggered pipelines display on each job's page, but only
users with the Owner and Maintainer role can view the values.

![Job variables in UI](img/trigger_variables.png)

## Revoke a trigger token

To revoke a trigger token:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Pipeline triggers**.
1. To the left of the trigger token you want to revoke, select **Revoke** (**{remove}**).

A revoked trigger token cannot be added back.

## Configure CI/CD jobs to run in triggered pipelines

To [configure when to run jobs](../jobs/job_control.md) in triggered pipelines:

- Use [`rules`](../yaml/index.md#rules) with the `$CI_PIPELINE_SOURCE` [predefined CI/CD variable](../variables/predefined_variables.md).
- Use [`only`/`except`](../yaml/index.md#onlyrefs--exceptrefs) keywords.

| `$CI_PIPELINE_SOURCE` value | `only`/`except` keywords | Trigger method      |
|-----------------------------|--------------------------|---------------------|
| `trigger`                   | `triggers`               | In pipelines triggered with the [pipeline triggers API](../../api/pipeline_triggers.md) by using a [trigger token](#create-a-trigger-token). |
| `pipeline`                  | `pipelines`              | In [multi-project pipelines](../pipelines/multi_project_pipelines.md#create-multi-project-pipelines-by-using-the-api) triggered with the [pipeline triggers API](../../api/pipeline_triggers.md) by using the [`$CI_JOB_TOKEN`](../jobs/ci_job_token.md), or by using the [`trigger`](../yaml/index.md#trigger) keyword in the CI/CD configuration file. |

Additionally, the `$CI_PIPELINE_TRIGGERED` predefined CI/CD variable is set to `true`
in pipelines triggered with a trigger token.

## See which trigger token was used

You can see which trigger caused a job to run by visiting the single job page.
A part of the trigger's token displays on the right of the page, under the job details:

![Marked as triggered on a single job page](img/trigger_single_job.png)

In pipelines triggered with a trigger token, jobs are labeled as `triggered` in
**CI/CD > Jobs**.

## Troubleshooting

### `404 not found` when triggering a pipeline

A response of `{"message":"404 Not Found"}` when triggering a pipeline might be caused
by using a [personal access token](../../user/profile/personal_access_tokens.md)
instead of a trigger token. [Create a new trigger token](#create-a-trigger-token)
and use it instead of the personal access token.
