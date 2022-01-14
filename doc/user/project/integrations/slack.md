---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Slack notifications service **(FREE)**

The Slack notifications service enables your GitLab project to send events
(such as issue creation) to your existing Slack team as notifications. Setting up
Slack notifications requires configuration changes for both Slack and GitLab.

You can also use [Slack slash commands](slack_slash_commands.md)
to control GitLab from Slack. Slash commands are configured separately.

## Configure Slack

1. Sign in to your Slack team and [start a new Incoming WebHooks configuration](https://my.slack.com/services/new/incoming-webhook).
1. Identify the Slack channel where notifications should be sent to by default.
   Select **Add Incoming WebHooks integration** to add the configuration.
1. Copy the **Webhook URL** to use later when you configure GitLab.

## Configure GitLab

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Slack notifications**.
1. In the **Enable integration** section, select the **Active** checkbox.
1. In the **Trigger** section, select the checkboxes for each type of GitLab
   event to send to Slack as a notification. For a full list, see
   [Triggers for Slack notifications](#triggers-for-slack-notifications).
   By default, messages are sent to the channel you configured during
   [Slack configuration](#configure-slack).
1. Optional. To send messages to a different channel, multiple channels, or as
   a direct message:
   - *To send messages to channels,* enter the Slack channel names, separated by
     commas.
   - *To send direct messages,* use the Member ID found in the user's Slack profile.

   NOTE:
   Usernames and private channels are not supported.

1. In **Webhook**, enter the webhook URL you copied in the
   [Slack configuration](#configure-slack) step.
1. Optional. In **Username**, enter the username of the Slack bot that sends
   the notifications.
1. Select the **Notify only broken pipelines** checkbox to notify only on failures.
1. In the **Branches for which notifications are to be sent** dropdown, select which types of branches
   to send notifications for.
1. Leave the **Labels to be notified** field blank to get all notifications, or
   add labels that the issue or merge request must have to trigger a
   notification.
1. Select **Test settings** to verify your information, and then select
   **Save changes**.

Your Slack team now starts receiving GitLab event notifications as configured.

## Triggers for Slack notifications

The following triggers are available for Slack notifications:

| Trigger name             | Trigger event                                           |
| ------------------------ | ------------------------------------------------------  |
| **Push**                 | A push to the repository.                               |
| **Issue**                | An issue is created, updated, or closed.                |
| **Confidential issue**   | A confidential issue is created, updated, or closed.    |
| **Merge request**        | A merge request is created, updated, or merged.         |
| **Note**                 | A comment is added.                                     |
| **Confidential note**    | A confidential note is added.                           |
| **Tag push**             | A new tag is pushed to the repository.                  |
| **Pipeline**             | A pipeline status changed.                              |
| **Wiki page**            | A wiki page is created or updated.                      |
| **Deployment**           | A deployment starts or finishes.                        |
| **Alert**                | A new, unique alert is recorded.                        |
| **Vulnerability**        | **(ULTIMATE)** A new, unique vulnerability is recorded. |

## Troubleshooting

If your Slack integration is not working, start troubleshooting by
searching through the [Sidekiq logs](../../../administration/logs.md#sidekiqlog)
for errors relating to your Slack service.

### Something went wrong on our end

You might get this generic error message in the GitLab UI.
Review [the logs](../../../administration/logs.md#productionlog) to find
the error message and keep troubleshooting from there.

### `certificate verify failed`

You might see an entry like the following in your Sidekiq log:

```plaintext
2019-01-10_13:22:08.42572 2019-01-10T13:22:08.425Z 6877 TID-abcdefg ProjectServiceWorker JID-3bade5fb3dd47a85db6d78c5 ERROR: {:class=>"ProjectServiceWorker", :service_class=>"SlackService", :message=>"SSL_connect returned=1 errno=0 state=error: certificate verify failed"}
```

This issue occurs when there is a problem with GitLab communicating with Slack,
or GitLab communicating with itself.
The former is less likely, as Slack security certificates should always be trusted.

To view which of these problems is the cause of the issue:

1. Start a Rails console:

   ```shell
   sudo gitlab-rails console -e production

   # for source installs:
   bundle exec rails console -e production
   ```

1. Run the following commands:

   ```ruby
   # replace <SLACK URL> with your actual Slack URL
   result = Net::HTTP.get(URI('https://<SLACK URL>'));0

   # replace <GITLAB URL> with your actual GitLab URL
   result = Net::HTTP.get(URI('https://<GITLAB URL>'));0
   ```

If GitLab does not trust HTTPS connections to itself,
[add your certificate to the GitLab trusted certificates](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates).

If GitLab does not trust connections to Slack,
the GitLab OpenSSL trust store is incorrect. Typical causes are:

- Overriding the trust store with `gitlab_rails['env'] = {"SSL_CERT_FILE" => "/path/to/file.pem"}`.
- Accidentally modifying the default CA bundle `/opt/gitlab/embedded/ssl/certs/cacert.pem`.
