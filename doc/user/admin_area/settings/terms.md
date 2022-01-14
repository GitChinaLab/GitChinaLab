---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Terms of Service and Privacy Policy **(FREE SELF)**

An administrator can enforce acceptance of a terms of service and privacy policy.
When this option is enabled, new and existing users must accept the terms.

When enabled, you can view the Terms of Service at the `-/users/terms` page on the instance,
for example `https://gitlab.example.com/-/users/terms`.

## Enforce a Terms of Service and Privacy Policy

To enforce acceptance of a Terms of Service and Privacy Policy:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Terms of Service and Privacy Policy** section.
1. Check the **All users must accept the Terms of Service and Privacy Policy to access GitLab** checkbox.
1. Input the text of the **Terms of Service and Privacy Policy**. You can use [Markdown](../../markdown.md)
   in this text box.
1. Click **Save changes**.

For each update to the terms, a new version is stored. When a user accepts or declines the terms,
GitLab records which version they accepted or declined.

Existing users must accept the terms on their next GitLab interaction.
If a signed-in user declines the terms, they are signed out.

When enabled, it adds a mandatory checkbox to the sign up page for new users:

![Sign up form](img/sign_up_terms.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
