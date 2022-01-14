---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Configure your GitLab installation **(FREE SELF)**

Customize and configure your self-managed GitLab installation. Here are some quick links to get you started:

- [Authentication](auth/index.md)
- [Configuration](../user/admin_area/index.md)
- [Repository storage](repository_storage_paths.md)
- [Geo](geo/index.md)
- [Packages](packages/index.md)

The following tables are intended to guide you to choose the right combination of capabilties based on your requirements. It is common to want the most
available, quickly recoverable, highly performant and fully data resilient solution. However, there are tradeoffs.

The tables lists features on the left and provides their capabilities to the right along with known trade-offs.

## Gitaly Capabilities

| | Availability | Recoverability | Data Resiliency | Performance | Risks/Trade-offs|
|-|--------------|----------------|-----------------|-------------|-----------------|
|Gitaly Cluster | Very high - tolerant of node failures | RTO for a single node of 10s with no manual intervention | Data is stored on multiple nodes | Good - While writes may take slightly longer due to voting, read distribution improves read speeds | **Trade-off** - Slight decrease in write speed for redundant, strongly-consistent storage solution. **Risks** - [Does not currently support snapshot backups](gitaly/index.md#snapshot-backup-and-recovery-limitations), GitLab backup task can be slow for large data sets |
|Gitaly Shards | Single storage location is a single point of failure | Would need to restore only shards which failed | Single point of failure | Good - can allocate repositories to shards to spread load | **Trade-off** - Need to manually configure repositories into different shards to balance loads / storage space **Risks** - Single point of failure relies on recovery process when single-node failure occurs |
|Gitaly + NFS | Single storage location is a single point of failure | Single node failure requires restoration from backup | Single point of failure | Average - NFS is not ideally suited to large quantities of small reads / writes which can have a detrimental impact on performance | **Trade-off** - Easy and familiar administration though NFS is not ideally suited to Git demands **Risks** - Many instances of NFS compatibility issues which provide very poor customer experiences |

## Geo Capabilities

If your availabity needs to span multiple zones or multiple locations, please read about [Geo](geo/index.md).

| | Availability | Recoverability | Data Resiliency | Performance | Risks/Trade-offs|
|-|--------------|----------------|-----------------|-------------|-----------------|
|Geo| Depends on the architecture of the Geo site. It is possible to deploy secondaries in single and multiple node configurations. | Eventually consistent. Recovery point depends on replication lag, which depends on a number of factors such as network speeds. Geo supports failover from a primary to secondary site using manual commands that are scriptable. | Geo currently replicates 100% of planned data types and verifies 50%. See [limitations table](geo/replication/datatypes.md#limitations-on-replicationverification) for more detail. | Improves read/clone times for users of a secondary.  | Geo is not intended to replace other backup/restore solutions. Because of replication lag and the possibility of replicating bad data from a primary, we recommend that customers also take regular backups of their primary site and test the restore process. |

## Scenarios for failure modes and available mitigation paths

The following table outlines failure modes and mitigation paths for the product offerings detailed in the tables above. Note - Gitaly Cluster install assumes an odd number replication factor of 3 or greater

| Gitaly Mode | Loss of Single Gitaly Node | Application / Data Corruption | Regional Outage (Loss of Instance) | Notes |
| ----------- | -------------------------- | ----------------------------- | ---------------------------------- | ----- |
| Single Gitaly Node | Downtime - Must restore from backup | Downtime - Must restore from Backup | Downtime - Must wait for outage to end | |
| Single Gitaly Node + Geo Secondary | Downtime - Must restore from backup, can perform a manual failover to secondary | Downtime - Must restore from Backup, errors could have propagated to secondary | Manual intervention - failover to Geo secondary | |
| Sharded Gitaly Install | Partial Downtime - Only repos on impacted node affected, must restore from backup | Partial Downtime - Only repos on impacted node affected, must restore from backup | Downtime - Must wait for outage to end | |
| Sharded Gitaly Install + Geo Secondary | Partial Downtime - Only repos on impacted node affected, must restore from backup, could perform manual failover to secondary for impacted repos | Partial Downtime - Only repos on impacted node affected, must restore from backup, errors could have propagated to secondary | Manual intervention - failover to Geo secondary | |
| Gitaly Cluster Install* | No Downtime - will swap repository primary to another node after 10 seconds | N/A - All writes are voted on by multiple Gitaly Cluster nodes | Downtime - Must wait for outage to end | Snapshot backups for Gitaly Cluster nodes not supported at this time |
| Gitaly Cluster Install* + Geo Secondary | No Downtime - will swap repository primary to another node after 10 seconds | N/A - All writes are voted on by multiple Gitaly Cluster nodes | Manual intervention - failover to Geo secondary | Snapshot backups for Gitaly Cluster nodes not supported at this time |
