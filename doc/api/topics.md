---
stage: Manage
group: Workspace
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Topics API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340920) in GitLab 14.5.

Interact with project topics using the REST API.

## List topics

Returns a list of project topics in the GitLab instance ordered by number of associated projects.

```plaintext
GET /topics
```

Supported attributes:

| Attribute  | Type    | Required               | Description |
| ---------- | ------- | ---------------------- | ----------- |
| `page`     | integer | **{dotted-circle}** No | Page to retrieve. Defaults to `1`.                      |
| `per_page` | integer | **{dotted-circle}** No | Number of records to return per page. Defaults to `20`. |
| `search`   | string  | **{dotted-circle}** No | Search topics against their `name`.                     |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/topics?search=git"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "GitLab",
    "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
    "total_projects_count": 1000,
    "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
  },
  {
    "id": 3,
    "name": "Git",
    "description": "Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.",
    "total_projects_count": 900,
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
  },
  {
    "id": 2,
    "name": "Git LFS",
    "description": null,
    "total_projects_count": 300,
    "avatar_url": null
  }
]
```

## Get a topic

Get a project topic by ID.

```plaintext
GET /topics/:id
```

Supported attributes:

| Attribute | Type    | Required               | Description         |
| --------- | ------- | ---------------------- | ------------------- |
| `id`      | integer | **{check-circle}** Yes | ID of project topic |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/topics/1"
```

Example response:

```json
{
  "id": 1,
  "name": "GitLab",
  "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
  "total_projects_count": 1000,
  "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
}
```

## List projects assigned to a topic

Use the [Projects API](projects.md#list-all-projects) to list all projects assigned to a specific topic.

```plaintext
GET /projects?topic=<topic_name>
```

## Create a project topic

Create a new project topic. Only available to administrators.

```plaintext
POST /topics
```

Supported attributes:

| Attribute     | Type    | Required               | Description |
| ------------- | ------- | ---------------------- | ----------- |
| `name`        | string  | **{check-circle}** Yes | Name        |
| `avatar`      | file    | **{dotted-circle}** No | Avatar      |
| `description` | string  | **{dotted-circle}** No | Description |

Example request:

```shell
curl --request POST \
     --data "name=topic1" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics"
```

Example response:

```json
{
  "id": 1,
  "name": "topic1",
  "description": null,
  "total_projects_count": 0,
  "avatar_url": null
}
```

## Update a project topic

Update a project topic. Only available to administrators.

```plaintext
PUT /topics/:id
```

Supported attributes:

| Attribute     | Type    | Required               | Description         |
| ------------- | ------- | ---------------------- | ------------------- |
| `id`          | integer | **{check-circle}** Yes | ID of project topic |
| `avatar`      | file    | **{dotted-circle}** No | Avatar              |
| `description` | string  | **{dotted-circle}** No | Description         |
| `name`        | string  | **{dotted-circle}** No | Name                |

Example request:

```shell
curl --request PUT \
     --data "name=topic1" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics/1"
```

Example response:

```json
{
  "id": 1,
  "name": "topic1",
  "description": null,
  "total_projects_count": 0,
  "avatar_url": null
}
```

### Upload a topic avatar

To upload an avatar file from your file system, use the `--form` argument. This argument causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to a file on your file system and be preceded by
`@`. For example:

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics/1" \
     --form "avatar=@/tmp/example.png"
```

### Remove a topic avatar

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348148) in GitLab 14.6.

To remove a topic avatar, use a blank value for the `avatar` attribute.

Example request:

```shell
curl --request PUT \
     --data "avatar=" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics/1"
```
