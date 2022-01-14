---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Fast lookup of authorized SSH keys in the database **(FREE SELF)**

NOTE:
This document describes a drop-in replacement for the
`authorized_keys` file. For normal (non-deploy key) users, consider using
[SSH certificates](ssh_certificates.md). They are even faster, but are not a
drop-in replacement.

Regular SSH operations become slow as the number of users grows because OpenSSH
searches for a key to authorize a user via a linear search. In the worst case,
such as when the user is not authorized to access GitLab, OpenSSH will scan the
entire file to search for a key. This can take significant time and disk I/O,
which delays users attempting to push or pull to a repository. Making
matters worse, if users add or remove keys frequently, the operating system may
not be able to cache the `authorized_keys` file, which causes the disk to be
accessed repeatedly.

GitLab Shell solves this by providing a way to authorize SSH users via a fast,
indexed lookup in the GitLab database. This page describes how to enable the fast
lookup of authorized SSH keys.

WARNING:
OpenSSH version 6.9+ is required because `AuthorizedKeysCommand` must be
able to accept a fingerprint. Check the version of OpenSSH on your server.

## Fast lookup is required for Geo **(PREMIUM)**

By default, GitLab manages an `authorized_keys` file that is located in the
`git` user's home directory. For most installations, this will be located under
`/var/opt/gitlab/.ssh/authorized_keys`, but you can use the following command to locate the `authorized_keys` on your system.:

```shell
getent passwd git | cut -d: -f6 | awk '{print $1"/.ssh/authorized_keys"}'
```

The `authorized_keys` file contains all the public SSH keys for users allowed to access GitLab. However, to maintain a
single source of truth, [Geo](../geo/index.md) needs to be configured to perform SSH fingerprint
lookups via database lookup.

As part of [setting up Geo](../geo/index.md#setup-instructions),
you are required to follow the steps outlined below for both the primary and
secondary nodes, but the `Write to "authorized keys" file` checkbox
only needs to be unchecked on the primary node since it is reflected
automatically on the secondary if database replication is working.

## Setting up fast lookup via GitLab Shell

GitLab Shell provides a way to authorize SSH users via a fast, indexed lookup
to the GitLab database. GitLab Shell uses the fingerprint of the SSH key to
check whether the user is authorized to access GitLab.

Add the following to your `sshd_config` file. This is usually located at
`/etc/ssh/sshd_config`, but it will be `/assets/sshd_config` if you're using
Omnibus Docker:

```plaintext
Match User git    # Apply the AuthorizedKeysCommands to the git user only
  AuthorizedKeysCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k
  AuthorizedKeysCommandUser git
Match all    # End match, settings apply to all users again
```

Reload OpenSSH:

```shell
# Debian or Ubuntu installations
sudo service ssh reload

# CentOS installations
sudo service sshd reload
```

Confirm that SSH is working by commenting out your user's key in the `authorized_keys`
file (start the line with a `#` to comment it), and attempting to pull a repository.

A successful pull would mean that GitLab was able to find the key in the database,
since it is not present in the file anymore.

NOTE:
For Omnibus Docker, `AuthorizedKeysCommand` is setup by default in
GitLab 11.11 and later.

NOTE:
For Installations from source, the command would be located at
`/home/git/gitlab-shell/bin/gitlab-shell-authorized-keys-check` if [the install from source](../../install/installation.md#install-gitlab-shell) instructions were followed.
You might want to consider creating a wrapper script somewhere else since this command needs to be
owned by `root` and not be writable by group or others. You could also consider changing the ownership of this command
as required, but that might require temporary ownership changes during `gitlab-shell` upgrades.

WARNING:
Do not disable writes until SSH is confirmed to be working
perfectly; otherwise, the file quickly becomes out-of-date.

In the case of lookup failures (which are common), the `authorized_keys`
file is still scanned. So Git SSH performance would still be slow for many
users as long as a large file exists.

To disable writes to the `authorized_keys` file:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Performance optimization**.
1. Clear the **Use authorized_keys file to authenticate SSH keys** checkbox.
1. Select **Save changes**.

Again, confirm that SSH is working by removing your user's SSH key in the UI,
adding a new one, and attempting to pull a repository.

Then you can backup and delete your `authorized_keys` file for best performance.
The current users' keys are already present in the database, so there is no need for migration
or for asking users to re-add their keys.

## How to go back to using the `authorized_keys` file

This is a brief overview. Please refer to the above instructions for more context.

1. [Rebuild the `authorized_keys` file](../raketasks/maintenance.md#rebuild-authorized_keys-file).
1. Enable writes to the `authorized_keys` file.
   1. On the top bar, select **Menu > Admin**.
   1. On the left sidebar, select **Settings > Network**.
   1. Expand **Performance optimization**.
   1. Select the **Use authorized_keys file to authenticate SSH keys** checkbox.
1. Remove the `AuthorizedKeysCommand` lines from `/etc/ssh/sshd_config` or from `/assets/sshd_config` if you are using Omnibus Docker.
1. Reload `sshd`: `sudo service sshd reload`.

## Use `gitlab-sshd` instead of OpenSSH

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299109) in GitLab 14.5.

WARNING:
`gitlab-sshd` is in [**Alpha**](https://about.gitlab.com/handbook/product/gitlab-the-product/#alpha-beta-ga).
It is not ready for production use.

`gitlab-sshd` is [a standalone SSH server](https://gitlab.com/gitlab-org/gitlab-shell/-/tree/main/internal/sshd)
 written in Go. It is provided as a part of `gitlab-shell` package. It has a lower memory
 use as a OpenSSH alternative and supports
 [group access restriction by IP address](../../user/group/index.md) for applications
 running behind the proxy.

If you are considering switching from OpenSSH to `gitlab-sshd`, consider these concerns:

- The `gitlab-sshd` component is only available for
  [Cloud Native Helm Charts](https://docs.gitlab.com/charts/) deployments.
- `gitlab-sshd` supports the PROXY protocol. It can run behind proxy servers that rely
  on it, such as HAProxy.
- `gitlab-sshd` does not share a SSH port with the system administrator's OpenSSH,
  and requires a bind to port 22.
- `gitlab-sshd` **does not** support SSH certificates.

To switch from OpenSSH to `gitlab-sshd`:

1. Set the `gitlab-shell` charts `sshDaemon` option to
   [`gitlab-sshd`](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/index.html#installation-command-line-options).
   For example:

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
   ```

1. Perform a Helm upgrade.

## SELinux support and limitations

GitLab supports `authorized_keys` database lookups with [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux).

Because the SELinux policy is static, GitLab doesn't support the ability to change
internal webserver ports at the moment. Administrators would have to create a special `.te`
file for the environment, since it isn't generated dynamically.
