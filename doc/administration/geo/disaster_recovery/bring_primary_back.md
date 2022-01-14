---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Bring a demoted primary site back online **(PREMIUM SELF)**

After a failover, it is possible to fail back to the demoted **primary** site to
restore your original configuration. This process consists of two steps:

1. Making the old **primary** site a **secondary** site.
1. Promoting a **secondary** site to a **primary** site.

WARNING:
If you have any doubts about the consistency of the data on this site, we recommend setting it up from scratch.

## Configure the former **primary** site to be a **secondary** site

Since the former **primary** site will be out of sync with the current **primary** site, the first step is to bring the former **primary** site up to date. Note, deletion of data stored on disk like
repositories and uploads will not be replayed when bringing the former **primary** site back
into sync, which may result in increased disk usage.
Alternatively, you can [set up a new **secondary** GitLab instance](../setup/index.md) to avoid this.

To bring the former **primary** site up to date:

1. SSH into the former **primary** site that has fallen behind.
1. Make sure all the services are up:

   ```shell
   sudo gitlab-ctl start
   ```

   NOTE:
   If you [disabled the **primary** site permanently](index.md#step-2-permanently-disable-the-primary-site),
   you need to undo those steps now. For Debian/Ubuntu you just need to run
   `sudo systemctl enable gitlab-runsvdir`. For CentOS 6, you need to install
   the GitLab instance from scratch and set it up as a **secondary** site by
   following [Setup instructions](../setup/index.md). In this case, you don't need to follow the next step.

   NOTE:
   If you [changed the DNS records](index.md#step-4-optional-updating-the-primary-domain-dns-record)
   for this site during disaster recovery procedure you may need to [block
   all the writes to this site](planned_failover.md#prevent-updates-to-the-primary-node)
   during this procedure.

1. [Set up database replication](../setup/database.md). In this case, the **secondary** site
   refers to the former **primary** site.
   1. If [PgBouncer](../../postgresql/pgbouncer.md) was enabled on the **current secondary** site
      (when it was a primary site) disable it by editing `/etc/gitlab/gitlab.rb`
      and running `sudo gitlab-ctl reconfigure`.
   1. You can then set up database replication on the **secondary** site.

If you have lost your original **primary** site, follow the
[setup instructions](../setup/index.md) to set up a new **secondary** site.

## Promote the **secondary** site to **primary** site

When the initial replication is complete and the **primary** site and **secondary** site are
closely in sync, you can do a [planned failover](planned_failover.md).

## Restore the **secondary** site

If your objective is to have two sites again, you need to bring your **secondary**
site back online as well by repeating the first step
([configure the former **primary** site to be a **secondary** site](#configure-the-former-primary-site-to-be-a-secondary-site))
for the **secondary** site.
