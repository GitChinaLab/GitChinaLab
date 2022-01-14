---
type: reference, howto
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Insights **(ULTIMATE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/725) in GitLab 12.0.

Configure the Insights that matter for your groups. Explore data such as
triage hygiene, issues created or closed for a given period, average time for merge
requests to be merged, and much more.

![Insights example stacked bar chart](img/insights_example_stacked_bar_chart_v13_11.png)

## View your group's Insights

To access your group's Insights:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Insights**.

## Configure your Insights

GitLab reads Insights from the [default configuration file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/fixtures/insights/default.yml).
If you want to customize it:

1. Create a new file [`.gitlab/insights.yml`](../../project/insights/index.md)
in a project that belongs to your group.
1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Insights**.
1. Select the project that contains your `.gitlab/insights.yml` configuration file.
1. Select **Save changes**.

## Permissions

If you have access to view a group, then you have access to view its Insights.

NOTE:
Issues or merge requests that you don't have access to (because you don't have
access to the project they belong to, or because they are confidential) are
filtered out of the Insights charts.

You may also consult the [group permissions table](../../permissions.md#group-members-permissions).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
