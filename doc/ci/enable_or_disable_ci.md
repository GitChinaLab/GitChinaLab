---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# How to enable or disable GitLab CI/CD **(FREE)**

To use GitLab CI/CD, you need:

- A valid [`.gitlab-ci.yml`](yaml/index.md) file present at the root directory
  of your project.
- A [runner](runners/index.md) ready to run jobs.

You can read our [quick start guide](quick_start/index.md) to get you started.

If you use an external CI/CD server like Jenkins or Drone CI, you can
disable GitLab CI/CD to avoid conflicts with the commits status
API.

GitLab CI/CD is enabled by default on all new projects. You can:

- Disable GitLab CI/CD [under each project's settings](#enable-cicd-in-a-project).
- Set GitLab CI/CD to be [disabled in all new projects on an instance](../administration/cicd.md).

If you disable GitLab CI/CD in a project:

- The **CI/CD** item in the left sidebar is removed.
- The `/pipelines` and `/jobs` pages are no longer available.
- Existing jobs and pipelines are not deleted. Re-enable CI/CD to access them again.

The project or instance settings do not enable or disable pipelines run in an
[external integration](../user/project/integrations/overview.md#integrations-listing).

## Enable CI/CD in a project

To enable or disable GitLab CI/CD pipelines in your project:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. In the **Repository** section, turn on or off **CI/CD** as required.

**Project visibility** also affects pipeline visibility. If set to:

- **Private**: Only project members can access pipelines.
- **Internal** or **Public**: Pipelines can be set to either **Only Project Members**
  or **Everyone With Access** by using the dropdown box.

Press **Save changes** for the settings to take effect.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
