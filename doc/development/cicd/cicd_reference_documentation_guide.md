---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# CI/CD YAML reference style guide **(FREE)**

The [CI/CD YAML reference](../../ci/yaml/index.md) uses a standard style to make it easier to use and update.

The reference information should be kept as simple as possible, and expanded details
and examples should be documented on other pages.

## YAML reference structure

Every YAML keyword must have its own section in the reference. The sections should
be nested so that the keywords follow a logical tree structure. For example:

```markdown
### `artifacts`
#### `artifacts:name`
#### `artifacts:paths`
#### `artifacts:reports`
##### `artifacts:reports:dast`
##### `artifacts:reports:sast`
```

## YAML reference style

Each keyword entry in the reference:

- Must have a simple introductory section. The introduction should give the fundamental
  information needed to use the keyword. Advanced details and tasks should be in
  feature pages, not the reference page.

- Must use the keyword name as the title, for example:

  ```markdown
  ### `artifacts`
  ```

- Should include the following sections:
  - [Keyword type](#keyword-type)
  - [Possible inputs](#possible-inputs)
  - [Example of `keyword-name`](#example-of-keyword-name)
- (Optional) Can also include the following sections when needed:
  - [Additional details](#additional-details)
  - [Related topics](#related-topics)

The keyword name must always be in backticks without a final `:`, like `artifacts`, not `artifacts:`.
If it is a subkey of another keyword, write out all the subkeys to the "parent" key the first time it
is used, like `artifacts:reports:dast`. Afterwards, you can use just the subkey alone, like `dast`.

## Keyword type

The keyword can be either a job or global keyword. If it can be used in a `default`
section, make not of that as well, for example:

- `**Keyword type**: Global keyword.`
- `**Keyword type**: Job keyword. You can use it only as part of a job.`
- ``**Keyword type**: Job keyword. You can use it only as part of a job or in the [`default:` section](#default).``

### Possible inputs

List all the possible inputs, and any extra details about the inputs, such as defaults
or changes due to different GitLab versions, for example:

```markdown
**Possible inputs**:

- `true` (default if not defined) or `false`.
```

```markdown
**Possible inputs**:

- A single exit code.
- An array of exit codes.
```

```markdown
**Possible inputs**:

- A string with the long description.
- The path to a file that contains the description. Introduced in [GitLab 13.7](https://gitlab.com/gitlab-org/release-cli/-/merge_requests/67).
  - The file location must be relative to the project directory (`$CI_PROJECT_DIR`).
  - If the file is a symbolic link, it must be in the `$CI_PROJECT_DIR`.
  - The `./path/to/file` and filename can't contain spaces.
```

### Example of `keyword-name`

An example of the keyword. Use the minimum number of other keywords necessary
to make the example valid. If the example needs explanation, add it after the example,
for example:

````markdown
**Example of `dast`**:

```yaml
stages:
  - build
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  dast_configuration:
    site_profile: "Example Co"
    scanner_profile: "Quick Passive Test"
```

In this example, the `dast` job extends the `dast` configuration added with the `include:` keyword
to select a specific site profile and scanner profile.
````

### Additional details

The additional details should be an unordered list of extra information that is
useful to know, but not important enough to put in the introduction. This information
can include changes introduced in different GitLab versions. For example:

```markdown
**Additional details**:

- The expiration time period begins when the artifact is uploaded and stored on GitLab.
  If the expiry time is not defined, it defaults to the [instance wide setting](../../user/admin_area/settings/continuous_integration.md#default-artifacts-expiration).
- To override the expiration date and protect artifacts from being automatically deleted:
  - Select **Keep** on the job page.
  - [In GitLab 13.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/22761), set the value of
    `expire_in` to `never`.
```

### Related topics

The related topics should be an unordered list of crosslinks to related pages, including:

- Specific tasks that you can accomplish with the keyword.
- Advanced examples of the keyword.
- Other related keywords that can be used together with this keyword.

For example:

```markdown
**Related topics**:

- You can specify a [fallback cache key](../caching/index.md#use-a-fallback-cache-key)
  to use if the specified `cache:key` is not found.
- You can [use multiple cache keys](../caching/index.md#use-multiple-caches) in a single job.
- See the [common `cache` use cases](../caching/index.md#common-use-cases-for-caches) for more
  `cache:key` examples.
```
