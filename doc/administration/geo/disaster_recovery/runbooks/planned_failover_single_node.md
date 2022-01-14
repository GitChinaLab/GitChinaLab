---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

WARNING:
This runbook is in **alpha**. For complete, production-ready documentation, see the
[disaster recovery documentation](../index.md).

# Disaster Recovery (Geo) promotion runbooks **(PREMIUM SELF)**

## Geo planned failover for a single-node configuration

| Component   | Configuration   |
|-------------|-----------------|
| PostgreSQL  | Omnibus-managed |
| Geo site    | Single-node     |
| Secondaries | One             |

This runbook guides you through a planned failover of a single-node Geo site
with one secondary. The following general architecture is assumed:

```mermaid
graph TD
  subgraph main[Geo deployment]
    subgraph Primary[Primary site]
      Node_1[(GitLab node)]
    end
    subgraph Secondary1[Secondary site]
      Node_2[(GitLab node)]
    end
  end
```

This guide results in the following:

1. An offline primary.
1. A promoted secondary that is now the new primary.

What is not covered:

1. Re-adding the old **primary** as a secondary.
1. Adding a new secondary.

### Preparation

NOTE:
Before following any of those steps, make sure you have `root` access to the
**secondary** to promote it, since there isn't provided an automated way to
promote a Geo replica and perform a failover.

NOTE:
GitLab 13.9 through GitLab 14.3 are affected by a bug in which the Geo secondary site statuses appears to stop updating and become unhealthy. For more information, see [Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode](../../replication/troubleshooting.md#geo-admin-area-shows-unhealthy-after-enabling-maintenance-mode).

On the **secondary** site, navigate to the **Admin Area > Geo** dashboard to
review its status. Replicated objects (shown in green) should be close to 100%,
and there should be no failures (shown in red). If a large proportion of
objects aren't yet replicated (shown in gray), consider giving the site more
time to complete.

![Replication status](../../replication/img/geo_dashboard_v14_0.png)

If any objects are failing to replicate, this should be investigated before
scheduling the maintenance window. After a planned failover, anything that
failed to replicate is **lost**.

You can use the
[Geo status API](../../../../api/geo_nodes.md#retrieve-project-sync-or-verification-failures-that-occurred-on-the-current-node)
to review failed objects and the reasons for failure.
A common cause of replication failures is the data being missing on the
**primary** site - you can resolve these failures by restoring the data from backup,
or removing references to the missing data.

The maintenance window does not end until Geo replication and verification is
completely finished. To keep the window as short as possible, you should
ensure these processes are close to 100% as possible during active use.

If the **secondary** site is still replicating data from the **primary** site,
follow these steps to avoid unnecessary data loss:

1. Until a [read-only mode](https://gitlab.com/gitlab-org/gitlab/-/issues/14609)
   is implemented, updates must be prevented from happening manually to the
   **primary**. Your **secondary** site still needs read-only
   access to the **primary** site during the maintenance window:

   1. At the scheduled time, using your cloud provider or your node's firewall, block
      all HTTP, HTTPS and SSH traffic to/from the **primary** node, **except** for your IP and
      the **secondary** node's IP.

      For instance, you can run the following commands on the **primary** node:

      ```shell
      sudo iptables -A INPUT -p tcp -s <secondary_node_ip> --destination-port 22 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 22 -j ACCEPT
      sudo iptables -A INPUT --destination-port 22 -j REJECT

      sudo iptables -A INPUT -p tcp -s <secondary_node_ip> --destination-port 80 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 80 -j ACCEPT
      sudo iptables -A INPUT --tcp-dport 80 -j REJECT

      sudo iptables -A INPUT -p tcp -s <secondary_node_ip> --destination-port 443 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 443 -j ACCEPT
      sudo iptables -A INPUT --tcp-dport 443 -j REJECT
      ```

      From this point, users are unable to view their data or make changes on the
      **primary** site. They are also unable to log in to the **secondary** site.
      However, existing sessions need to work for the remainder of the maintenance period, and
      so public data is accessible throughout.

   1. Verify the **primary** site is blocked to HTTP traffic by visiting it in browser via
      another IP. The server should refuse connection.

   1. Verify the **primary** site is blocked to Git over SSH traffic by attempting to pull an
      existing Git repository with an SSH remote URL. The server should refuse
      connection.

   1. On the **primary** site:
      1. On the top bar, select **Menu > Admin**.
      1. On the left sidebar, select **Monitoring > Background Jobs**.
      1. On the Sidekiq dhasboard, select **Cron**.
      1. Select `Disable All` to disable any non-Geo periodic background jobs.
      1. Select `Enable` for the `geo_sidekiq_cron_config_worker` cron job.
         This job re-enables several other cron jobs that are essential for planned
         failover to complete successfully.

1. Finish replicating and verifying all data:

   WARNING:
   Not all data is automatically replicated. Read more about
   [what is excluded](../planned_failover.md#not-all-data-is-automatically-replicated).

   1. If you are manually replicating any
      [data not managed by Geo](../../replication/datatypes.md#limitations-on-replicationverification),
      trigger the final replication process now.
   1. On the **primary** site:
      1. On the top bar, select **Menu > Admin**.
      1. On the left sidebar, select **Monitoring > Background Jobs**.
      1. On the Sidekiq dashboard, select **Queues**, and wait for all queues except
         those with `geo` in the name to drop to 0.
         These queues contain work that has been submitted by your users; failing over
         before it is completed, causes the work to be lost.
      1. On the left sidebar, select **Geo > Nodes** and wait for the
         following conditions to be true of the **secondary** site you are failing over to:

         - All replication meters reach 100% replicated, 0% failures.
         - All verification meters reach 100% verified, 0% failures.
         - Database replication lag is 0ms.
         - The Geo log cursor is up to date (0 events behind).

   1. On the **secondary** site:
      1. On the top bar, select **Menu > Admin**.
      1. On the left sidebar, select **Monitoring > Background Jobs**.
      1. On the Sidekiq dashboard, select **Queues**, and wait for all the `geo`
         queues to drop to 0 queued and 0 running jobs.
      1. [Run an integrity check](../../../raketasks/check.md) to verify the integrity
         of CI artifacts, LFS objects, and uploads in file storage.

   At this point, your **secondary** site contains an up-to-date copy of everything the
   **primary** site has, meaning nothing is lost when you fail over.

1. In this final step, you need to permanently disable the **primary** site.

   WARNING:
   When the **primary** site goes offline, there may be data saved on the **primary** site
   that has not been replicated to the **secondary** site. This data should be treated
   as lost if you proceed.

   NOTE:
   If you plan to [update the **primary** domain DNS record](../index.md#step-4-optional-updating-the-primary-domain-dns-record),
   you may wish to lower the TTL now to speed up propagation.

   When performing a failover, we want to avoid a split-brain situation where
   writes can occur in two different GitLab instances. So to prepare for the
   failover, you must disable the **primary** site:

   - If you have SSH access to the **primary** site, stop and disable GitLab:

     ```shell
     sudo gitlab-ctl stop
     ```

     Prevent GitLab from starting up again if the server unexpectedly reboots:

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

     NOTE:
     (**CentOS only**) In CentOS 6 or older, there is no easy way to prevent GitLab from being
     started if the machine reboots isn't available (see [Omnibus GitLab issue #3058](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3058)).
     It may be safest to uninstall the GitLab package completely with `sudo yum remove gitlab-ee`.

     NOTE:
     (**Ubuntu 14.04 LTS**) If you are using an older version of Ubuntu
     or any other distribution based on the Upstart init system, you can prevent GitLab
     from starting if the machine reboots as `root` with
     `initctl stop gitlab-runsvvdir && echo 'manual' > /etc/init/gitlab-runsvdir.override && initctl reload-configuration`.

   - If you do not have SSH access to the **primary** site, take the machine offline and
     prevent it from rebooting. Since there are many ways you may prefer to accomplish
     this, we avoid a single recommendation. You may need to:

     - Reconfigure the load balancers.
     - Change DNS records (for example, point the **primary** DNS record to the
       **secondary** site to stop using the **primary** site).
     - Stop the virtual servers.
     - Block traffic through a firewall.
     - Revoke object storage permissions from the **primary** site.
     - Physically disconnect a machine.

### Promoting the **secondary** site

Note the following when promoting a secondary:

- A new **secondary** should not be added at this time. If you want to add a new
  **secondary**, do this after you have completed the entire process of promoting
  the **secondary** to the **primary**.
- If you encounter an `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken`
  error during this process, read
  [the troubleshooting advice](../../replication/troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-node).

To promote the secondary site running GitLab 14.5 and later:

1. SSH in to your **secondary** node and run one of the following commands:

   - To promote the secondary node to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the secondary node to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Verify you can connect to the newly promoted **primary** site using the URL used
   previously for the **secondary** site.

   If successful, the **secondary** site is now promoted to the **primary** site.

To promote the secondary site running GitLab 14.4 and earlier:

WARNING:
The `gitlab-ctl promote-to-primary-node` and `gitlab-ctl promoted-db` commands are
deprecated in GitLab 14.5 and later, and are scheduled to [be removed in GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/345207).
Use `gitlab-ctl geo promote` instead.

1. SSH in to your **secondary** site and login as root:

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb` to reflect its new status as **primary** by
   removing any lines that enabled the `geo_secondary_role`:

   ```ruby
   ## In pre-11.5 documentation, the role was enabled as follows. Remove this line.
   geo_secondary_role['enable'] = true

   ## In 11.5+ documentation, the role was enabled as follows. Remove this line.
   roles ['geo_secondary_role']
   ```

1. Run the following command to list out all preflight checks and automatically
   check if replication and verification are complete before scheduling a planned
   failover to ensure the process goes smoothly:

   NOTE:
   In GitLab 13.7 and earlier, if you have a data type with zero items to sync,
   this command reports `ERROR - Replication is not up-to-date` even if
   replication is actually up-to-date. This bug was fixed in GitLab 13.8 and
   later.

   ```shell
   gitlab-ctl promotion-preflight-checks
   ```

1. Promote the **secondary**:

   NOTE:
   In GitLab 13.7 and earlier, if you have a data type with zero items to sync,
   this command reports `ERROR - Replication is not up-to-date` even if
   replication is actually up-to-date. If replication and verification output
   shows that it is complete, you can add `--skip-preflight-checks` to make the
   command complete promotion. This bug was fixed in GitLab 13.8 and later.

   ```shell
   gitlab-ctl promote-to-primary-node
   ```

   If you have already run the [preflight checks](../planned_failover.md#preflight-checks)
   or don't want to run them, you can skip them:

   ```shell
   gitlab-ctl promote-to-primary-node --skip-preflight-check
   ```

   You can also promote the secondary site to primary **without any further confirmation**, even when preflight checks fail:

   ```shell
   sudo gitlab-ctl promote-to-primary-node --force
   ```

1. Verify you can connect to the newly promoted **primary** site using the URL used
   previously for the **secondary** site.

   If successful, the **secondary** site is now promoted to the **primary** site.

### Next steps

To regain geographic redundancy as quickly as possible, you should
[add a new **secondary** site](../../setup/index.md). To
do that, you can re-add the old **primary** as a new secondary and bring it back
online.
