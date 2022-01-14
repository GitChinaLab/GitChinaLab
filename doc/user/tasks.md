---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Tasks **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334812) in GitLab 14.5 [with a flag](../administration/feature_flags.md) named `work_items`. Disabled by default.

WARNING:
Tasks are in **Alpha**. Current implementation does not have any API requests and works with mocked data.
For the latest updates, check the [Tasks Roadmap](https://gitlab.com/groups/gitlab-org/-/epics/7103).

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
ask an administrator to [enable the feature flag](../administration/feature_flags.md) named `work_items`.
On GitLab.com, this feature is not available.
The feature is not ready for production use.

Use tasks to track steps needed for the [issue](project/issues/index.md) to be closed.

When planning an issue, you need a way to capture and break down technical
requirements or steps necessary to complete it. An issue with related tasks is better defined,
and so you can provide a more accurate issue weight and completion criteria.

Tasks are a type of work item, a step towards [default issue types](https://gitlab.com/gitlab-org/gitlab/-/issues/323404)
in GitLab.
For the roadmap of migrating issues and [epics](group/epics/index.md)
to work items and adding custom work item types, visit
[epic 6033](https://gitlab.com/groups/gitlab-org/-/epics/6033) or
[Plan direction page](https://about.gitlab.com/direction/plan/).

## View a task

The only way to view a task is to open it with a deep link,
for example: `/<group_name>/<project_name>/-/work_item/1`.
