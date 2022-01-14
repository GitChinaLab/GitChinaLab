---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Usage statistics **(FREE SELF)**

GitLab Inc. periodically collects information about your instance in order
to perform various actions.

All usage statistics are [opt-out](#enable-or-disable-usage-statistics).

## Service Ping

Service Ping is a process that collects and sends a weekly payload to GitLab Inc.
For more information, see the [Service Ping guide](../../../development/service_ping/index.md).

### Instance-level analytics availability

When Service Ping is enabled, GitLab gathers data from other instances and
enables certain [instance-level analytics features](../analytics/index.md)
that are dependent on Service Ping.

## Version check

If enabled, version check informs you if a new version is available and the
importance of it through a status. The status displays on the help pages (`/help`)
for all signed-in users, and on the Admin Area pages. The statuses are:

- Green: You are running the latest version of GitLab.
- Orange: An updated version of GitLab is available.
- Red: The version of GitLab you are running is vulnerable. You should install
  the latest version with security fixes as soon as possible.

![Orange version check example](img/update-available.png)

GitLab Inc. collects your instance's version and hostname (through the HTTP
referer) as part of the version check. No other information is collected.

This information is used, among other things, to identify to which versions
patches must be backported, making sure active GitLab instances remain
secure.

If you [disable version check](#enable-or-disable-usage-statistics), this information isn't collected.

### Request flow example

The following example shows a basic request/response flow between a
self-managed GitLab instance and the GitLab Version Application:

```mermaid
sequenceDiagram
    participant GitLab instance
    participant Version Application
    GitLab instance->>Version Application: Is there a version update?
    loop Version Check
        Version Application->>Version Application: Record version info
    end
    Version Application->>GitLab instance: Response (PNG/SVG)
```

## Configure your network

To send usage statistics to GitLab Inc., you must allow network traffic from your
GitLab instance to the IP address `104.196.17.203:443`.

If your GitLab instance is behind a proxy, set the appropriate
[proxy configuration variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html).

## Enable or disable usage statistics

To enable or disable Service Ping and version check:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > Metrics and profiling**.
1. Expand **Usage statistics**.
1. Select or clear the **Enable version check** and **Enable Service Ping** checkboxes.
1. Select **Save changes**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
