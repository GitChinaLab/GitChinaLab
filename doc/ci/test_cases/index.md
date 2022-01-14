---
stage: Plan
group: Certify
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: Test cases in GitLab can help your teams create testing scenarios in their existing development platform.
type: reference
---

# Test Cases **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/233479) in GitLab 13.6.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/241983) in GitLab 13.7.

INFO:
Create test cases in GitLab Ultimate.
[Try it free for 30 days](https://about.gitlab.com/free-trial/index.html?glm_source=docs.gitlab.com&glm_content=u-test-cases-docs).

Test cases in GitLab can help your teams create testing scenarios in their existing development platform.

Now your Implementation and Testing teams can collaborate better, as they no longer have to
use external test planning tools, which require additional overhead, context switching, and expense.

## Create a test case

Prerequisite:

- You must have at least the Reporter [role](../../user/permissions.md).

To create a test case in a GitLab project:

1. Go to **CI/CD > Test Cases**.
1. Select the **New test case** button. You are taken to the new test case form. Here you can enter
   the new case's title, [description](../../user/markdown.md), attach a file, and assign [labels](../../user/project/labels.md).
1. Select the **Submit test case** button. You are taken to view the new test case.

## View a test case

You can view all test cases in the project in the Test Cases list. Filter the
issue list with a search query, including labels or the test case's title.

Prerequisite:

- You must have at least the Guest [role](../../user/permissions.md).

To view a test case:

1. In a project, go to **CI/CD > Test Cases**.
1. Select the title of the test case you want to view. You are taken to the test case page.

![An example test case page](img/test_case_show_v13_10.png)

## Edit a test case

You can edit a test case's title and description.

Prerequisite:

- You must have at least the Reporter [role](../../user/permissions.md).
- Users demoted to the Guest role can continue to edit the test cases they created
when they were in the higher role.

To edit a test case:

1. [View a test case](#view-a-test-case).
1. Select **Edit title and description** (**{pencil}**).
1. Edit the test case's title or description.
1. Select **Save changes**.

## Archive a test case

When you want to stop using a test case, you can archive it. You can [reopen an archived test case](#reopen-an-archived-test-case) later.

Prerequisite:

- You must have at least the Reporter [role](../../user/permissions.md).

To archive a test case, on the test case's page, select the **Archive test case** button.

To view archived test cases:

1. Go to **CI/CD > Test Cases**.
1. Select **Archived**.

## Reopen an archived test case

If you decide to start using an archived test case again, you can reopen it.

You must have at least the Reporter [role](../../user/permissions.md).

To reopen an archived test case, on the test case's page, select **Reopen test case**.
