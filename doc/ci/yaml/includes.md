---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# GitLab CI/CD include examples **(FREE)**

You can use [`include`](index.md#include) to include external YAML files in your CI/CD jobs.

## Include a single configuration file

To include a single configuration file, use either of these syntax options:

- `include` by itself with a single file, which is the same as
  [`include:local`](index.md#includelocal):

  ```yaml
  include: '/templates/.after-script-template.yml'
  ```

- `include` with a single file, and you specify the `include` type:

  ```yaml
  include:
    remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  ```

## Include an array of configuration files

You can include an array of configuration files:

- If you do not specify an `include` type, the type defaults to [`include:local`](index.md#includelocal):

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - '/templates/.after-script-template.yml'
  ```

- You can define a single item array:

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  ```

- You can define an array and explicitly specify multiple `include` types:

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - local: '/templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
  ```

- You can define an array that combines both default and specific `include` type:

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - '/templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
    - project: 'my-group/my-project'
      ref: main
      file: '/templates/.gitlab-ci-template.yml'
  ```

## Use `default` configuration from an included configuration file

You can define a [`default`](index.md#default) section in a
configuration file. When you use a `default` section with the `include` keyword, the defaults apply to
all jobs in the pipeline.

For example, you can use a `default` section with [`before_script`](index.md#before_script).

Content of a custom configuration file named `/templates/.before-script-template.yml`:

```yaml
default:
  before_script:
    - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
    - gem install bundler --no-document
    - bundle install --jobs $(nproc)  "${FLAGS[@]}"
```

Content of `.gitlab-ci.yml`:

```yaml
include: '/templates/.before-script-template.yml'

rspec1:
  script:
    - bundle exec rspec

rspec2:
  script:
    - bundle exec rspec
```

The default `before_script` commands execute in both `rspec` jobs, before the `script` commands.

## Override included configuration values

When you use the `include` keyword, you can override the included configuration values to adapt them
to your pipeline requirements.

The following example shows an `include` file that is customized in the
`.gitlab-ci.yml` file. Specific YAML-defined variables and details of the
`production` job are overridden.

Content of a custom configuration file named `autodevops-template.yml`:

```yaml
variables:
  POSTGRES_USER: user
  POSTGRES_PASSWORD: testing_password
  POSTGRES_DB: $CI_ENVIRONMENT_SLUG

production:
  stage: production
  script:
    - install_dependencies
    - deploy
  environment:
    name: production
    url: https://$CI_PROJECT_PATH_SLUG.$KUBE_INGRESS_BASE_DOMAIN
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'https://company.com/autodevops-template.yml'

image: alpine:latest

variables:
  POSTGRES_USER: root
  POSTGRES_PASSWORD: secure_password

stages:
  - build
  - test
  - production

production:
  environment:
    url: https://domain.com
```

The `POSTGRES_USER` and `POSTGRES_PASSWORD` variables
and the `environment:url` of the `production` job defined in the `.gitlab-ci.yml` file
override the values defined in the `autodevops-template.yml` file. The other keywords
do not change. This method is called *merging*.

## Override included configuration arrays

You can use merging to extend and override configuration in an included template, but
you cannot add or modify individual items in an array. For example, to add
an additional `notify_owner` command to the extended `production` job's `script` array:

Content of `autodevops-template.yml`:

```yaml
production:
  stage: production
  script:
    - install_dependencies
    - deploy
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'autodevops-template.yml'

stages:
  - production

production:
  script:
    - install_dependencies
    - deploy
    - notify_owner
```

If `install_dependencies` and `deploy` are not repeated in
the `.gitlab-ci.yml` file, the `production` job would have only `notify_owner` in the script.

## Use nested includes

You can nest `include` sections in configuration files that are then included
in another configuration. For example, for `include` keywords nested three deep:

Content of `.gitlab-ci.yml`:

```yaml
include:
  - local: /.gitlab-ci/another-config.yml
```

Content of `/.gitlab-ci/another-config.yml`:

```yaml
include:
  - local: /.gitlab-ci/config-defaults.yml
```

Content of `/.gitlab-ci/config-defaults.yml`:

```yaml
default:
  after_script:
    - echo "Job complete."
```

## Use variables with `include`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/284883) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/294294) in GitLab 13.9.
> - [Support for project, group, and instance variables added](https://gitlab.com/gitlab-org/gitlab/-/issues/219065) in GitLab 14.2.
> - [Support for pipeline variables added](https://gitlab.com/gitlab-org/gitlab/-/issues/337633) in GitLab 14.5.

In `include` sections in your `.gitlab-ci.yml` file, you can use:

- [Project variables](../variables/index.md#add-a-cicd-variable-to-a-project)
- [Group variables](../variables/index.md#add-a-cicd-variable-to-a-group)
- [Instance variables](../variables/index.md#add-a-cicd-variable-to-an-instance)
- Project [predefined variables](../variables/predefined_variables.md)
- In GitLab 14.2 and later, the `$CI_COMMIT_REF_NAME` [predefined variable](../variables/predefined_variables.md).

  When used in `include`, the `CI_COMMIT_REF_NAME` variable returns the full
  ref path, like `refs/heads/branch-name`. In `include:rules`, you might need to use
  `if: $CI_COMMIT_REF_NAME =~ /main/` (not `== main`). This behavior is resolved in GitLab 14.5.

In GitLab 14.5 and later, you can also use:

- [Trigger variables](../triggers/index.md#pass-cicd-variables-in-the-api-call).
- [Scheduled pipeline variables](../pipelines/schedules.md#using-variables).
- [Manual pipeline run variables](../variables/index.md#override-a-variable-when-running-a-pipeline-manually).
- Pipeline [predefined variables](../variables/predefined_variables.md).

  YAML files are parsed before the pipeline is created, so the following pipeline predefined variables
  are **not** available:

  - `CI_PIPELINE_ID`
  - `CI_PIPELINE_URL`
  - `CI_PIPELINE_IID`
  - `CI_PIPELINE_CREATED_AT`

For example:

```yaml
include:
  project: '$CI_PROJECT_PATH'
  file: '.compliance-gitlab-ci.yml'
```

For an example of how you can include these predefined variables, and the variables' impact on CI/CD jobs,
see this [CI/CD variable demo](https://youtu.be/4XR8gw3Pkos).

## Use `rules` with `include`

> - Introduced in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ci_include_rules`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/337507) in GitLab 14.3.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/337507) GitLab 14.3.
> - [Feature flag `ci_include_rules` removed](https://gitlab.com/gitlab-org/gitlab/-/issues/337507) in GitLab 14.4.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/337507) in GitLab 14.4.
> - [Support for `exists` keyword added](https://gitlab.com/gitlab-org/gitlab/-/issues/341511) in GitLab 14.5.

You can use [`rules`](index.md#rules) with `include` to conditionally include other configuration files.

You can only use the following rules with `include` (and only with [certain variables](#use-variables-with-include)):

- [`if` rules](index.md#rulesif). For example:

  ```yaml
  include:
    - local: builds.yml
      rules:
        - if: '$INCLUDE_BUILDS == "true"'
    - local: deploys.yml
      rules:
        - if: $CI_COMMIT_BRANCH == "main"

  test:
    stage: test
    script: exit 0
  ```

- [`exists` rules](index.md#rulesexists). For example:

  ```yaml
  include:
    - local: builds.yml
      rules:
        - exists:
            - file.md

  test:
    stage: test
    script: exit 0
  ```

`rules` keyword `changes` is not supported.

## Use `include:local` with wildcard file paths

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25921) in GitLab 13.11.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/327315) in GitLab 14.2.

You can use wildcard paths (`*` and `**`) with `include:local`.

Example:

```yaml
include: 'configs/*.yml'
```

When the pipeline runs, GitLab:

- Adds all `.yml` files in the `configs` directory into the pipeline configuration.
- Does not add `.yml` files in subfolders of the `configs` directory. To allow this,
  add the following configuration:

  ```yaml
  # This matches all `.yml` files in `configs` and any subfolder in it.
  include: 'configs/**.yml'

  # This matches all `.yml` files only in subfolders of `configs`.
  include: 'configs/**/*.yml'
  ```
