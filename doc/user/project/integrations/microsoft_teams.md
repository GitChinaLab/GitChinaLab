---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Microsoft Teams service **(FREE)**

You can integrate Microsoft Teams with GitLab, and display notifications about GitLab projects
in Microsoft Teams. To integrate the services, you must:

1. [Configure Microsoft Teams](#configure-microsoft-teams) to enable a webhook
   to listen for changes.
1. [Configure your GitLab project](#configure-your-gitlab-project) to push notifications
   to the Microsoft Teams webhook.

## Configure Microsoft Teams

To configure Microsoft Teams to listen for notifications from GitLab:

1. In Microsoft Teams, type `incoming webhook` in the search bar, and select
   **Incoming Webhook**:

   ![Select Incoming Webhook](img/microsoft_teams_select_incoming_webhook.png)

1. Select **Add to a team**.
1. Select the team and channel you want to add the integration to.
1. Add a name for the webhook. The name is displayed next to every message that
   comes in through the webhook.
1. Copy the webhook URL, as you need it to configure GitLab.

## Configure your GitLab project

After you configure Microsoft Teams to receive notifications, you must configure
GitLab to send the notifications:

1. Sign in to GitLab as an administrator.
1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Microsoft Teams notifications**.
1. To enable the integration, select **Active**.
1. In the **Trigger** section, select the checkbox next to each event to enable it:
   - Push
   - Issue
   - Confidential issue
   - Merge request
   - Note
   - Confidential note
   - Tag push
   - Pipeline
   - Wiki page
1. In **Webhook**, paste the URL you copied when you
   [configured Microsoft Teams](#configure-microsoft-teams).
1. Optional. If you enable the pipeline trigger, select the
   **Notify only broken pipelines** checkbox to push notifications only when pipelines break.
1. Select the branches you want to send notifications for.
1. Select **Save changes**.

## Related topics

- [Setting up an incoming webhook on Microsoft Teams](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using#setting-up-a-custom-incoming-webhook).
