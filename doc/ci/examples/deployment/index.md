---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: tutorial
---

# Using Dpl as a deployment tool **(FREE)**

[Dpl](https://github.com/travis-ci/dpl) (pronounced like the letters D-P-L) is a deploy tool made for
continuous deployment that's developed and used by Travis CI, but can also be
used with GitLab CI/CD.

Dpl can be used to deploy to any of the [supported providers](https://github.com/travis-ci/dpl#supported-providers).

## Requirements

To use Dpl you need at least Ruby 1.9.3 with ability to install gems.

## Basic usage

Dpl can be installed on any machine with:

```shell
gem install dpl
```

This allows you to test all commands from your local terminal, rather than
having to test it on a CI server.

If you don't have Ruby installed you can do it on Debian-compatible Linux with:

```shell
apt-get update
apt-get install ruby-dev
```

The Dpl provides support for vast number of services, including: Heroku, Cloud Foundry, AWS/S3, and more.
To use it simply define provider and any additional parameters required by the provider.

For example if you want to use it to deploy your application to Heroku, you need to specify `heroku` as provider, specify `api_key` and `app`.
All possible parameters can be found in the [Heroku API section](https://github.com/travis-ci/dpl#heroku-api).

```yaml
staging:
  stage: deploy
  script:
    - gem install dpl
    - dpl --provider=heroku --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
```

In the above example we use Dpl to deploy `my-app-staging` to Heroku server with API key stored in `HEROKU_STAGING_API_KEY` secure variable.

To use different provider take a look at long list of [Supported Providers](https://github.com/travis-ci/dpl#supported-providers).

## Using Dpl with Docker

In most cases, you configured [GitLab Runner](https://docs.gitlab.com/runner/) to use your server's shell commands.
This means that all commands are run in the context of local user (for example `gitlab_runner` or `gitlab_ci_multi_runner`).
It also means that most probably in your Docker container you don't have the Ruby runtime installed.
You must install it:

```yaml
staging:
  stage: deploy
  script:
    - apt-get update -yq
    - apt-get install -y ruby-dev
    - gem install dpl
    - dpl --provider=heroku --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  only:
    - main
```

The first line `apt-get update -yq` updates the list of available packages,
where second `apt-get install -y ruby-dev` installs the Ruby runtime on system.
The above example is valid for all Debian-compatible systems.

## Usage in staging and production

It's pretty common in the development workflow to have staging (development) and
production environments

Let's consider the following example: we would like to deploy the `main`
branch to `staging` and all tags to the `production` environment.
The final `.gitlab-ci.yml` for that setup would look like this:

```yaml
staging:
  stage: deploy
  script:
    - gem install dpl
    - dpl --provider=heroku --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  only:
    - main

production:
  stage: deploy
  script:
    - gem install dpl
    - dpl --provider=heroku --app=my-app-production --api_key=$HEROKU_PRODUCTION_API_KEY
  only:
    - tags
```

We created two deploy jobs that are executed on different events:

- `staging`: Executed for all commits pushed to the `main` branch
- `production`: Executed for all pushed tags

We also use two secure variables:

- `HEROKU_STAGING_API_KEY`: Heroku API key used to deploy staging app
- `HEROKU_PRODUCTION_API_KEY`: Heroku API key used to deploy production app

## Storing API keys

To store API keys as secure variables:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Variables**.

The variables defined in the project settings are sent along with the build script to the runner.
The secure variables are stored out of the repository. Never store secrets in
your project's `.gitlab-ci.yml` file. It is also important that the secret's value
is hidden in the job log.

You access added variable by prefixing it's name with `$` (on non-Windows runners)
or `%` (for Windows Batch runners):

- `$VARIABLE`: Use for non-Windows runners
- `%VARIABLE%`: Use for Windows Batch runners

Read more about [CI/CD variables](../../variables/index.md).
