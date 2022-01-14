---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Permissions and roles

Users have different abilities depending on the role they have in a
particular group or project. If a user is both in a project's group and the
project itself, the highest role is used.

On [public and internal projects](../api/projects.md#project-visibility-level), the Guest role
(not to be confused with [Guest user](#free-guest-users)) is not enforced.

When a member leaves a team's project, all the assigned [issues](project/issues/index.md) and
[merge requests](project/merge_requests/index.md) are automatically unassigned.

GitLab [administrators](../administration/index.md) receive all permissions.

To add or import a user, you can follow the
[project members documentation](project/members/index.md).

## Principles behind permissions

See our [product handbook on permissions](https://about.gitlab.com/handbook/product/gitlab-the-product/#permissions-in-gitlab).

## Instance-wide user permissions

By default, users can create top-level groups and change their
usernames. A GitLab administrator can configure the GitLab instance to
[modify this behavior](../administration/user_settings.md).

## Project members permissions

A user's role determines what permissions they have on a project. The Owner role provides all permissions but is
available only:

- For group owners. The role is inherited for a group's projects.
- For Administrators.

Personal namespace owners have the same permissions as an Owner, but are displayed with the Maintainer role on projects created in their personal namespace.
For more information, see [projects members documentation](project/members/index.md).

The following table lists project permissions available for each role:

<!-- Keep this table sorted: By topic first, then by minimum role, then alphabetically. -->

| Action                                                                                                                  | Guest    | Reporter | Developer | Maintainer | Owner |
|-------------------------------------------------------------------------------------------------------------------------|----------|----------|-----------|------------|-------|
| [Analytics](analytics/index.md):<br>View issue analytics **(PREMIUM)**                                                  | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Analytics](analytics/index.md):<br>View [merge request analytics](analytics/merge_request_analytics.md) **(PREMIUM)**  | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Analytics](analytics/index.md):<br>View value stream analytics                                                         | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Analytics](analytics/index.md):<br>View [DORA metrics](analytics/ci_cd_analytics.md)                                   |          | ✓        | ✓         | ✓          | ✓     |
| [Analytics](analytics/index.md):<br>View [CI/CD analytics](analytics/ci_cd_analytics.md)                                |          | ✓        | ✓         | ✓          | ✓     |
| [Analytics](analytics/index.md):<br>View [code review analytics](analytics/code_review_analytics.md) **(PREMIUM)**      |          | ✓        | ✓         | ✓          | ✓     |
| [Analytics](analytics/index.md):<br>View [repository analytics](analytics/repository_analytics.md)                      |          | ✓        | ✓         | ✓          | ✓     |
| [Application security](application_security/index.md):<br>View licenses in [dependency list](application_security/dependency_list/index.md) **(ULTIMATE)**         | ✓ (*1*) | ✓ | ✓ | ✓ | ✓   |
| [Application security](application_security/index.md):<br>Create and run [on-demand DAST scans](application_security/dast/index.md#on-demand-scans) **(ULTIMATE)** |    |    | ✓   | ✓   | ✓   |
| [Application security](application_security/index.md):<br>Manage [security policy](application_security/policies/index.md) **(ULTIMATE)**                          |    |    | ✓   | ✓   | ✓   |
| [Application security](application_security/index.md):<br>View [dependency list](application_security/dependency_list/index.md) **(ULTIMATE)**                     |    |    | ✓   | ✓   | ✓   |
| [Application security](application_security/index.md):<br>View [threats list](application_security/threat_monitoring/index.md#threat-monitoring) **(ULTIMATE)**    |    |    | ✓   | ✓   | ✓   |
| [Application security](application_security/index.md):<br>Create a [CVE ID Request](application_security/cve_id_request.md) **(FREE SAAS)**                        |    |    |     | ✓   | ✓   |
| [Application security](application_security/index.md):<br>Create or assign [security policy project](application_security/policies/index.md) **(ULTIMATE)**        |    |    |     |     | ✓   |
| [CI/CD](../ci/index.md):<br>Download and browse job artifacts                                                          | ✓ (*3*)  | ✓        | ✓         | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>View a job log                                                                             | ✓ (*3*)  | ✓        | ✓         | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>View list of jobs                                                                          | ✓ (*3*)  | ✓        | ✓         | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>View [environments](../ci/environments/index.md)                                           |          | ✓        | ✓         | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Cancel and retry jobs                                                                      |          |          | ✓         | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Create new [environments](../ci/environments/index.md)                                     |          |          | ✓         | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Run CI/CD pipeline against a protected branch                                              |          |          | ✓ (*5*)   | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Stop [environments](../ci/environments/index.md)                                           |          |          | ✓         | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>View a job with [debug logging](../ci/variables/index.md#debug-logging)                    |          |          | ✓         | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Manage CI/CD variables                                                                     |          |          |           | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Manage job triggers                                                                        |          |          |           | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Manage runners                                                                             |          |          |           | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Run Web IDE's Interactive Web Terminals **(ULTIMATE ONLY)**                                |          |          |           | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Use [environment terminals](../ci/environments/index.md#web-terminals-deprecated)                     |          |          |           | ✓          | ✓     |
| [CI/CD](../ci/index.md):<br>Delete pipelines                                                                           |          |          |           |            | ✓     |
| [Clusters](infrastructure/clusters/index.md):<br>View [pod logs](project/clusters/kubernetes_pod_logs.md)                                                                 |          |          | ✓         | ✓          | ✓     |
| [Clusters](infrastructure/clusters/index.md):<br>Manage clusters                                                               |          |          |           | ✓          | ✓     |
| [Container Registry](packages/container_registry/index.md):<br>Create, edit, delete cleanup policies                    |          |          | ✓         | ✓          | ✓     |
| [Container Registry](packages/container_registry/index.md):<br>Remove a container registry image                        |          |          | ✓         | ✓          | ✓     |
| [Container Registry](packages/container_registry/index.md):<br>Update container registry                                |          |          | ✓         | ✓          | ✓     |
| [GitLab Pages](project/pages/index.md):<br>View Pages protected by [access control](project/pages/introduction.md#gitlab-pages-access-control) | ✓    | ✓    | ✓    | ✓    | ✓    |
| [GitLab Pages](project/pages/index.md):<br>Manage                                                                       |          |          |           | ✓          | ✓     |
| [GitLab Pages](project/pages/index.md):<br>Manage GitLab Pages domains and certificates                                 |          |          |           | ✓          | ✓     |
| [GitLab Pages](project/pages/index.md):<br>Remove GitLab Pages                                                          |          |          |           | ✓          | ✓     |
| [Incident Management](../operations/incident_management/index.md):<br>View [alerts](../operations/incident_management/alerts.md)                            |  | ✓ | ✓ | ✓ | ✓ |
| [Incident Management](../operations/incident_management/index.md):<br>Assign an alert                                                                       | ✓| ✓ | ✓ | ✓ | ✓ |
| [Incident Management](../operations/incident_management/index.md):<br>View [incident](../operations/incident_management/incidents.md)                       | ✓| ✓ | ✓ | ✓ | ✓ |
| [Incident Management](../operations/incident_management/index.md):<br>Create [incident](../operations/incident_management/incidents.md)                     | (*17*) | ✓ | ✓ | ✓ | ✓ |
| [Incident Management](../operations/incident_management/index.md):<br>View [on-call schedules](../operations/incident_management/oncall_schedules.md)       |  | ✓ | ✓ | ✓ | ✓ |
| [Incident Management](../operations/incident_management/index.md):<br>Participate in on-call rotation                                                       | ✓| ✓ | ✓ | ✓ | ✓ |
| [Incident Management](../operations/incident_management/index.md):<br>View [escalation policies](../operations/incident_management/escalation_policies.md)  |  | ✓ | ✓ | ✓ | ✓ |
| [Incident Management](../operations/incident_management/index.md):<br>Manage [on-call schedules](../operations/incident_management/oncall_schedules.md)     |  |   |   | ✓ | ✓ |
| [Incident Management](../operations/incident_management/index.md):<br>Manage [escalation policies](../operations/incident_management/escalation_policies.md)|  |   |   | ✓ | ✓ |
| [Issues](project/issues/index.md):<br>Add Labels                                                                        | ✓ (*16*) | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Assign                                                                            | ✓ (*16*) | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Create                                                                            | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Create [confidential issues](project/issues/confidential_issues.md)               | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>View [Design Management](project/issues/design_management.md) pages               | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>View related issues                                                               | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Set weight                                                                        | ✓ (*16*) | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>View [confidential issues](project/issues/confidential_issues.md)                 | (*2*)    | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Close / reopen                                                                    |          | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Lock threads                                                                      |          | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Manage related issues                                                             |          | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Manage tracker                                                                    |          | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Move issues (*15*)                                                                |          | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Set issue [time tracking](project/time_tracking.md) estimate and time spent       |          | ✓        | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Upload [Design Management](project/issues/design_management.md) files             |          |          | ✓         | ✓          | ✓     |
| [Issues](project/issues/index.md):<br>Delete                                                                            |          |          |           |            | ✓     |
| [License Compliance](compliance/license_compliance/index.md):<br>View allowed and denied licenses **(ULTIMATE)**        | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓     |
| [License Compliance](compliance/license_compliance/index.md):<br>View License Compliance reports **(ULTIMATE)**         | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓     |
| [License Compliance](compliance/license_compliance/index.md):<br>View License list **(ULTIMATE)**                       |          | ✓        | ✓         | ✓          | ✓     |
| [License Compliance](compliance/license_compliance/index.md):<br>Manage license policy **(ULTIMATE)**                   |          |          |           | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Assign reviewer                                                   |          | ✓        | ✓         | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>See list                                                          |          | ✓        | ✓         | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Apply code change suggestions                                     |          |          | ✓         | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Approve (*9*)                                                     |          |          | ✓         | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Assign                                                            |          |          | ✓         | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Create (*18*)                                                          |          |          | ✓         | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Add labels                                                        |          |          | ✓         | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Lock threads                                                      |          |          | ✓         | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Manage or accept                                                  |          |          | ✓         | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Manage merge approval rules (project settings)                    |          |          |           | ✓          | ✓     |
| [Merge requests](project/merge_requests/index.md):<br>Delete                                                            |          |          |           |            | ✓     |
| [Metrics dashboards](../operations/metrics/dashboards/index.md):<br>Manage user-starred metrics dashboards (*7*)        | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Metrics dashboards](../operations/metrics/dashboards/index.md):<br>View metrics dashboard annotations                  |          | ✓        | ✓         | ✓          | ✓     |
| [Metrics dashboards](../operations/metrics/dashboards/index.md):<br>Create/edit/delete metrics dashboard annotations    |          |          | ✓         | ✓          | ✓     |
| [Package registry](packages/index.md):<br>Pull package                                                                  | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓     |
| [Package registry](packages/index.md):<br>Publish package                                                               |          |          | ✓         | ✓          | ✓     |
| [Package registry](packages/index.md):<br>Delete package                                                                |          |          |           | ✓          | ✓     |
| [Project operations](../operations/index.md):<br>View [Error Tracking](../operations/error_tracking.md) list            |          | ✓        | ✓         | ✓          | ✓     |
| [Project operations](../operations/index.md):<br>Manage [Feature Flags](../operations/feature_flags.md) **(PREMIUM)**   |          |          | ✓         | ✓          | ✓     |
| [Project operations](../operations/index.md):<br>Manage [Error Tracking](../operations/error_tracking.md)               |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Download project                                                                       | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>Leave comments                                                                         | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>Reposition comments on images (posted by any user)                                     | ✓ (*10*) | ✓ (*10*) | ✓ (*10*)  | ✓          | ✓     |
| [Projects](project/index.md):<br>View Insights **(ULTIMATE)**                                                           | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>View [releases](project/releases/index.md)                                             | ✓ (*6*)  | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>View Requirements **(ULTIMATE)**                                                       | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>View [time tracking](project/time_tracking.md) reports                                 | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>View [wiki](project/wiki/index.md) pages                                               | ✓        | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>Create [snippets](snippets.md)                                                         |          | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>Manage labels                                                                          |          | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>View [project traffic statistics](../api/project_statistics.md)                        |          | ✓        | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>Create, edit, delete [milestones](project/milestones/index.md).                        |          |          | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>Create, edit, delete [releases](project/releases/index.md)                             |          |          | ✓ (*13*)  | ✓ (*13*)   | ✓ (*13*) |
| [Projects](project/index.md):<br>Create, edit [wiki](project/wiki/index.md) pages                                       |          |          | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>Enable Review Apps                                                                     |          |          | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>View project [Audit Events](../administration/audit_events.md)                         |          |          | ✓ (*11*)  | ✓          | ✓     |
| [Projects](project/index.md):<br>Add deploy keys                                                                        |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Add new team members                                                                   |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Change [project features visibility](../public_access/public_access.md) level          |          |          |           | ✓ (14)     | ✓     |
| [Projects](project/index.md):<br>Configure [webhooks](project/integrations/webhooks.md)                                                             |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Delete [wiki](project/wiki/index.md) pages                                             |          |          | ✓         | ✓          | ✓     |
| [Projects](project/index.md):<br>Edit comments (posted by any user)                                                     |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Edit project badges                                                                    |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Edit project settings                                                                  |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Export project                                                                         |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Manage [project access tokens](project/settings/project_access_tokens.md) **(FREE SELF)** **(PREMIUM SAAS)** (*12*) |     |     |    | ✓    | ✓    |
| [Projects](project/index.md):<br>Manage [Project Operations](../operations/index.md)                                    |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Share (invite) projects with groups                                                    |          |          |           | ✓ (*8*)    | ✓ (*8*) |
| [Projects](project/index.md):<br>View 2FA status of members                                                             |          |          |           | ✓          | ✓     |
| [Projects](project/index.md):<br>Administer project compliance frameworks                                               |          |          |           |            | ✓     |
| [Projects](project/index.md):<br>Archive project                                                                        |          |          |           |            | ✓     |
| [Projects](project/index.md):<br>Change project visibility level                                                        |          |          |           |            | ✓     |
| [Projects](project/index.md):<br>Delete project                                                                         |          |          |           |            | ✓     |
| [Projects](project/index.md):<br>Disable notification emails                                                            |          |          |           |            | ✓     |
| [Projects](project/index.md):<br>Rename project                                                                         |          |          |           |            | ✓     |
| [Projects](project/index.md):<br>Transfer project to another namespace                                                  |          |          |           |            | ✓     |
| [Repository](project/repository/index.md):<br>Pull project code                                                         | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>View project code                                                         | ✓ (*1*)  | ✓        | ✓         | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>View a commit status                                                      |          | ✓        | ✓         | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Add tags                                                                  |          |          | ✓         | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Create new branches                                                       |          |          | ✓         | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Create or update commit status                                            |          |          | ✓ (*5*)   | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Force push to non-protected branches                                      |          |          | ✓         | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Push to non-protected branches                                            |          |          | ✓         | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Remove non-protected branches                                             |          |          | ✓         | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Rewrite or remove Git tags                                                |          |          | ✓         | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Enable or disable branch protection                                       |          |          |           | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Enable or disable tag protection                                          |          |          |           | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Manage [push rules](../push_rules/push_rules.md)                          |          |          |           | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Push to protected branches (*5*)                                          |          |          |           | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Turn on or off protected branch push for developers                       |          |          |           | ✓          | ✓     |
| [Repository](project/repository/index.md):<br>Remove fork relationship                                                  |          |          |           |            | ✓     |
| [Repository](project/repository/index.md):<br>Force push to protected branches (*4*)                                    |          |          |           |            |       |
| [Repository](project/repository/index.md):<br>Remove protected branches (*4*)                                           |          |          |           |            |       |
| [Requirements Management](project/requirements/index.md):<br>Archive / reopen **(ULTIMATE)**                            |          | ✓        | ✓         | ✓          | ✓     |
| [Requirements Management](project/requirements/index.md):<br>Create / edit **(ULTIMATE)**                               |          | ✓        | ✓         | ✓          | ✓     |
| [Requirements Management](project/requirements/index.md):<br>Import / export **(ULTIMATE)**                             |          | ✓        | ✓         | ✓          | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>View Security reports **(ULTIMATE)**                           | ✓ (*3*) | ✓ | ✓     | ✓     | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Create issue from vulnerability finding **(ULTIMATE)**         |      |      | ✓     | ✓     | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Create vulnerability from vulnerability finding **(ULTIMATE)** |      |      | ✓     | ✓     | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Dismiss vulnerability **(ULTIMATE)**                           |      |      | ✓     | ✓     | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Dismiss vulnerability finding **(ULTIMATE)**                   |      |      | ✓     | ✓     | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Resolve vulnerability **(ULTIMATE)**                           |      |      | ✓     | ✓     | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Revert vulnerability to detected state **(ULTIMATE)**          |      |      | ✓     | ✓     | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>Use security dashboard **(ULTIMATE)**                          |      |      | ✓     | ✓     | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>View vulnerability **(ULTIMATE)**                              |      |      | ✓     | ✓     | ✓     |
| [Security dashboard](application_security/security_dashboard/index.md):<br>View vulnerability findings in [dependency list](application_security/dependency_list/index.md) **(ULTIMATE)** |      |      | ✓     | ✓     | ✓     |
| [Terraform](infrastructure/index.md):<br>Read Terraform state                                                           |          |          | ✓         | ✓          | ✓     |
| [Terraform](infrastructure/index.md):<br>Manage Terraform state                                                         |          |          |           | ✓          | ✓     |
| [Test cases](../ci/test_cases/index.md):<br>Archive                                                                     |          | ✓        | ✓         | ✓          | ✓     |
| [Test cases](../ci/test_cases/index.md):<br>Create                                                                      |          | ✓        | ✓         | ✓          | ✓     |
| [Test cases](../ci/test_cases/index.md):<br>Move                                                                        |          | ✓        | ✓         | ✓          | ✓     |
| [Test cases](../ci/test_cases/index.md):<br>Reopen                                                                      |          | ✓        | ✓         | ✓          | ✓     |

1. On self-managed GitLab instances, guest users are able to perform this action only on
   public and internal projects (not on private projects). [External users](#external-users)
   must be given explicit access even if the project is internal. For GitLab.com, see the
   [GitLab.com visibility settings](gitlab_com/index.md#visibility-settings).
1. Guest users can only view the [confidential issues](project/issues/confidential_issues.md) they created themselves.
1. If **Public pipelines** is enabled in **Project Settings > CI/CD**.
1. Not allowed for Guest, Reporter, Developer, Maintainer, or Owner. See [protected branches](project/protected_branches.md).
1. If the [branch is protected](project/protected_branches.md), this depends on the access Developers and Maintainers are given.
1. Guest users can access GitLab [**Releases**](project/releases/index.md) for downloading assets but are not allowed to download the source code nor see [repository information like commits and release evidence](project/releases/index.md#view-a-release-and-download-assets).
1. Actions are limited only to records owned (referenced) by user.
1. When [Share Group Lock](group/index.md#prevent-a-project-from-being-shared-with-groups) is enabled the project can't be shared with other groups. It does not affect group with group sharing.
1. For information on eligible approvers for merge requests, see
   [Eligible approvers](project/merge_requests/approvals/rules.md#eligible-approvers).
1. Applies only to comments on [Design Management](project/issues/design_management.md) designs.
1. Users can only view events based on their individual actions.
1. Project access tokens are supported for self-managed instances on Free and above. They are also
   supported on GitLab SaaS Premium and above (excluding [trial licenses](https://about.gitlab.com/free-trial/)).
1. If the [tag is protected](#release-permissions-with-protected-tags), this depends on the access Developers and Maintainers are given.
1. A Maintainer can't change project features visibility level if
   [project visibility](../public_access/public_access.md) is set to private.
1. Attached design files are moved together with the issue even if the user doesn't have the
   Developer role.
1. Guest users can only set metadata (for example, labels, assignees, or milestones)
   when creating an issue. They cannot change the metadata on existing issues.
1. In GitLab 14.5 or later, Guests are not allowed to [create incidents](../operations/incident_management/incidents.md#incident-creation).
1. In projects that accept contributions from external members, users can create, edit, and close their own merge requests.

## Project features permissions

### Wiki and issues

Project features like [wikis](project/wiki/index.md) and issues can be hidden from users depending on
which visibility level you select on project settings.

- Disabled: disabled for everyone
- Only team members: only team members can see even if your project is public or internal
- Everyone with access: everyone can see depending on your project's visibility level
- Everyone: enabled for everyone (only available for GitLab Pages)

### Protected branches

Additional restrictions can be applied on a per-branch basis with [protected branches](project/protected_branches.md).
Additionally, you can customize permissions to allow or prevent project
Maintainers and Developers from pushing to a protected branch. Read through the documentation on
[protected branches](project/protected_branches.md)
to learn more.

### Value Stream Analytics permissions

Find the current permissions on the Value Stream Analytics dashboard, as described in
[related documentation](analytics/value_stream_analytics.md#permissions).

### Issue board permissions

Find the current permissions for interacting with the issue board feature in the
[issue boards permissions page](project/issue_board.md#permissions).

### File Locking permissions **(PREMIUM)**

The user that locks a file or directory is the only one that can edit and push their changes back to the repository where the locked objects are located.

Read through the documentation on [permissions for File Locking](project/file_lock.md#permissions) to learn more.

### Confidential Issues permissions

[Confidential issues](project/issues/confidential_issues.md) can be accessed by users with reporter and higher permission levels,
as well as by guest users that create a confidential issue. To learn more,
read through the documentation on [permissions and access to confidential issues](project/issues/confidential_issues.md#permissions-and-access-to-confidential-issues).

### Container Registry visibility permissions

Find the visibility permissions for the Container Registry, as described in the
[related documentation](packages/container_registry/index.md#container-registry-visibility-permissions).

## Group members permissions

Any user can remove themselves from a group, unless they are the last Owner of
the group.

The following table lists group permissions available for each role:

<!-- Keep this table sorted: first, by minimum role, then alphabetically. -->

| Action                                                 | Guest | Reporter | Developer | Maintainer | Owner |
|--------------------------------------------------------|-------|----------|-----------|------------|-------|
| Browse group                                           | ✓     | ✓        | ✓         | ✓          | ✓     |
| Edit SAML SSO Billing **(PREMIUM SAAS)**               | ✓     | ✓        | ✓         | ✓          | ✓ (4) |
| Pull a container image using the dependency proxy      | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Contribution analytics                            | ✓     | ✓        | ✓         | ✓          | ✓     |
| View group epic **(PREMIUM)**                          | ✓     | ✓        | ✓         | ✓          | ✓     |
| View group wiki pages **(PREMIUM)**                    | ✓ (6) | ✓        | ✓         | ✓          | ✓     |
| View Insights **(ULTIMATE)**                           | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Insights charts **(ULTIMATE)**                    | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Issue analytics **(PREMIUM)**                     | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Value Stream analytics                            | ✓     | ✓        | ✓         | ✓          | ✓     |
| Create/edit group epic **(PREMIUM)**                   |       | ✓        | ✓         | ✓          | ✓     |
| Create/edit/delete epic boards **(PREMIUM)**           |       | ✓        | ✓         | ✓          | ✓     |
| Manage group labels                                    |       | ✓        | ✓         | ✓          | ✓     |
| Pull [packages](packages/index.md)                     |       | ✓        | ✓         | ✓          | ✓     |
| View a container registry                              |       | ✓        | ✓         | ✓          | ✓     |
| View Group DevOps Adoption **(ULTIMATE)**              |       | ✓        | ✓         | ✓          | ✓     |
| View metrics dashboard annotations                     |       | ✓        | ✓         | ✓          | ✓     |
| View Productivity analytics **(PREMIUM)**              |       | ✓        | ✓         | ✓          | ✓     |
| Create and edit group wiki pages **(PREMIUM)**         |       |          | ✓         | ✓          | ✓     |
| Create project in group                                |       |          | ✓ (3)(5)  | ✓ (3)      | ✓ (3) |
| Create/edit/delete group milestones                    |       |          | ✓         | ✓          | ✓     |
| Create/edit/delete iterations                          |       |          | ✓         | ✓          | ✓     |
| Create/edit/delete metrics dashboard annotations       |       |          | ✓         | ✓          | ✓     |
| Enable/disable a dependency proxy                      |       |          | ✓         | ✓          | ✓     |
| Purge the dependency proxy for a group                 |       |          |           |            | ✓     |
| Publish [packages](packages/index.md)                  |       |          | ✓         | ✓          | ✓     |
| Use security dashboard **(ULTIMATE)**                  |       |          | ✓         | ✓          | ✓     |
| View group Audit Events                                |       |          | ✓ (7)     | ✓ (7)      | ✓     |
| Create subgroup                                        |       |          |           | ✓ (1)      | ✓     |
| Delete group wiki pages **(PREMIUM)**                  |       |          | ✓         | ✓          | ✓     |
| Edit epic comments (posted by any user) **(ULTIMATE)** |       |          |           | ✓ (2)      | ✓ (2) |
| List group deploy tokens                               |       |          |           | ✓          | ✓     |
| Manage [group push rules](group/index.md#group-push-rules) **(PREMIUM)** | | |        | ✓          | ✓     |
| View/manage group-level Kubernetes cluster             |       |          |           | ✓          | ✓     |
| Administer project compliance frameworks               |       |          |           |            | ✓     |
| Create/Delete group deploy tokens                      |       |          |           |            | ✓     |
| Change group visibility level                          |       |          |           |            | ✓     |
| Delete group                                           |       |          |           |            | ✓     |
| Delete group epic **(PREMIUM)**                        |       |          |           |            | ✓     |
| Disable notification emails                            |       |          |           |            | ✓     |
| Edit group settings                                    |       |          |           |            | ✓     |
| Filter members by 2FA status                           |       |          |           |            | ✓     |
| Manage group level CI/CD variables                     |       |          |           |            | ✓     |
| Manage group members                                   |       |          |           |            | ✓     |
| Share (invite) groups with groups                      |       |          |           |            | ✓     |
| View 2FA status of members                             |       |          |           |            | ✓     |
| View Billing **(FREE SAAS)**                           |       |          |           |            | ✓ (4) |
| View Usage Quotas **(FREE SAAS)**                      |       |          |           |            | ✓ (4) |

1. Groups can be set to [allow either Owners or Owners and
  Maintainers to create subgroups](group/subgroups/index.md#creating-a-subgroup)
1. Introduced in GitLab 12.2.
1. Default project creation role can be changed at:
   - The [instance level](admin_area/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects).
   - The [group level](group/index.md#specify-who-can-add-projects-to-a-group).
1. Does not apply to subgroups.
1. Developers can push commits to the default branch of a new project only if the [default branch protection](group/index.md#change-the-default-branch-protection-of-a-group) is set to "Partially protected" or "Not protected".
1. In addition, if your group is public or internal, all users who can see the group can also see group wiki pages.
1. Users can only view events based on their individual actions.

### Subgroup permissions

When you add a member to a subgroup, they inherit the membership and
permission level from the parent group(s). This model allows access to
nested groups if you have membership in one of its parents.

To learn more, read through the documentation on
[subgroups memberships](group/subgroups/index.md#membership).

## External users **(FREE SELF)**

In cases where it is desired that a user has access only to some internal or
private projects, there is the option of creating **External Users**. This
feature may be useful when for example a contractor is working on a given
project and should only have access to that project.

External users:

- Can only create projects (including forks), subgroups, and snippets within the top-level group to which they belong.
- Can only access public projects and projects to which they are explicitly granted access,
  thus hiding all other internal or private ones from them (like being
  logged out).
- Can only access public groups and groups to which they are explicitly granted access,
  thus hiding all other internal or private ones from them (like being
  logged out).
- Can only access public snippets.

Access can be granted by adding the user as member to the project or group.
Like usual users, they receive a role in the project or group with all
the abilities that are mentioned in the [permissions table above](#project-members-permissions).
For example, if an external user is added as Guest, and your project is internal or
private, they do not have access to the code; you need to grant the external
user access at the Reporter level or above if you want them to have access to the code. You should
always take into account the
[project's visibility and permissions settings](project/settings/index.md#sharing-and-permissions)
as well as the permission level of the user.

NOTE:
External users still count towards a license seat.

An administrator can flag a user as external by either of the following methods:

- [Through the API](../api/users.md#user-modification).
- Using the GitLab UI:
  1. On the top bar, select **Menu > Admin**.
  1. On the left sidebar, select **Overview > Users** to create a new user or edit an existing one.
     There, you can find the option to flag the user as external.

Additionally users can be set as external users using:

- [SAML groups](../integration/saml.md#external-groups).
- [LDAP groups](../administration/auth/ldap/ldap_synchronization.md#external-groups).

### Setting new users to external

By default, new users are not set as external users. This behavior can be changed
by an administrator:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Account and limit** section.

If you change the default behavior of creating new users as external, you
have the option to narrow it down by defining a set of internal users.
The **Internal users** field allows specifying an email address regex pattern to
identify default internal users. New users whose email address matches the regex
pattern are set to internal by default rather than an external collaborator.

The regex pattern format is in Ruby, but it needs to be convertible to JavaScript,
and the ignore case flag is set (`/regex pattern/i`). Here are some examples:

- Use `\.internal@domain\.com$` to mark email addresses ending with
  `.internal@domain.com` as internal.
- Use `^(?:(?!\.ext@domain\.com).)*$\r?` to mark users with email addresses
  NOT including `.ext@domain.com` as internal.

WARNING:
Be aware that this regex could lead to a
[regular expression denial of service (ReDoS) attack](https://en.wikipedia.org/wiki/ReDoS).

## Free Guest users **(ULTIMATE)**

When a user is given the Guest role on a project, group, or both, and holds no
higher permission level on any other project or group on the GitLab instance,
the user is considered a guest user by GitLab and does not consume a license seat.
There is no other specific "guest" designation for newly created users.

If the user is assigned a higher role on any projects or groups, the user
takes a license seat. If a user creates a project, the user becomes a Maintainer
on the project, resulting in the use of a license seat. Also, note that if your
project is internal or private, Guest users have all the abilities that are
mentioned in the [permissions table above](#project-members-permissions) (they
are unable to browse the project's repository, for example).

NOTE:
To prevent a guest user from creating projects, as an administrator, you can edit the
user's profile to mark the user as [external](#external-users).
Beware though that even if a user is external, if they already have Reporter or
higher permissions in any project or group, they are **not** counted as a
free guest user.

## Auditor users **(PREMIUM SELF)**

Auditor users are given read-only access to all projects, groups, and other
resources on the GitLab instance.

An Auditor user should be able to access all projects and groups of a GitLab instance
with the permissions described on the documentation on [auditor users permissions](../administration/auditor_users.md#permissions-and-restrictions-of-an-auditor-user).

[Read more about Auditor users.](../administration/auditor_users.md)

## Users with minimal access **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40942) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.4.

Owners can add members with a "minimal access" role to a parent group. Such users don't
automatically have access to projects and subgroups underneath. To support such access, owners must explicitly add these "minimal access" users to the specific subgroups/projects.

Users with minimal access can list the group in the UI and through the API. However, they cannot see
details such as projects or subgroups. They do not have access to the group's page or list any of its subgroups or projects.

### Minimal access users take license seats

Users with even a "minimal access" role are counted against your number of license seats. This
requirement does not apply for [GitLab Ultimate](https://about.gitlab.com/pricing/)
subscriptions.

## Project features

Project features like wiki and issues can be hidden from users depending on
which visibility level you select on project settings.

- Disabled: disabled for everyone.
- Only team members: only team members can see, even if your project is public or internal.
- Everyone with access: everyone can see depending on your project visibility level.
- Everyone: enabled for everyone (only available for GitLab Pages).

## GitLab CI/CD permissions

GitLab CI/CD permissions rely on the role the user has in GitLab:

- Maintainer
- Developer
- Guest/Reporter

GitLab administrators can perform any action on GitLab CI/CD in scope of the GitLab
instance and project.

| Action                                | Guest, Reporter | Developer   |Maintainer| Administrator |
|---------------------------------------|-----------------|-------------|----------|---------------|
| See commits and jobs                  | ✓               | ✓           | ✓        | ✓             |
| Retry or cancel job                   |                 | ✓           | ✓        | ✓             |
| Erase job artifacts and job logs      |                 | ✓ (*1*)     | ✓        | ✓             |
| Delete project                        |                 |             | ✓        | ✓             |
| Create project                        |                 |             | ✓        | ✓             |
| Change project configuration           |                 |             | ✓        | ✓             |
| Add specific runners                   |                 |             | ✓        | ✓             |
| Add shared runners                    |                 |             |          | ✓             |
| See events in the system              |                 |             |          | ✓             |
| Admin Area                            |                 |             |          | ✓             |

1. Only if the job was:
   - Triggered by the user
   - [In GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/35069) and later, run for a non-protected branch.

### Job permissions

This table shows granted privileges for jobs triggered by specific types of
users:

| Action                                      | Guest, Reporter | Developer   |Maintainer| Administrator   |
|---------------------------------------------|-----------------|-------------|----------|---------|
| Run CI job                                  |                 | ✓           | ✓        | ✓       |
| Clone source and LFS from current project   |                 | ✓           | ✓        | ✓       |
| Clone source and LFS from public projects   |                 | ✓           | ✓        | ✓       |
| Clone source and LFS from internal projects |                 | ✓ (*1*)     | ✓  (*1*) | ✓       |
| Clone source and LFS from private projects  |                 | ✓ (*2*)     | ✓  (*2*) | ✓ (*2*) |
| Pull container images from current project  |                 | ✓           | ✓        | ✓       |
| Pull container images from public projects  |                 | ✓           | ✓        | ✓       |
| Pull container images from internal projects|                 | ✓ (*1*)     | ✓  (*1*) | ✓       |
| Pull container images from private projects |                 | ✓ (*2*)     | ✓  (*2*) | ✓ (*2*) |
| Push container images to current project    |                 | ✓           | ✓        | ✓       |
| Push container images to other projects     |                 |             |          |         |
| Push source and LFS                         |                 |             |          |         |

1. Only if the triggering user is not an external one
1. Only if the triggering user is a member of the project

## Running pipelines on protected branches

The permission to merge or push to protected branches is used to define if a user can
run CI/CD pipelines and execute actions on jobs that are related to those branches.

See [Security on protected branches](../ci/pipelines/index.md#pipeline-security-on-protected-branches)
for details about the pipelines security model.

## Release permissions with protected tags

[The permission to create tags](project/protected_tags.md) is used to define if a user can
create, edit, and delete [Releases](project/releases/index.md).

See [Release permissions](project/releases/index.md#release-permissions)
for more information.

## LDAP users permissions

LDAP user permissions can be manually overridden by an administrator.
Read through the documentation on [LDAP users permissions](group/index.md#manage-group-memberships-via-ldap) to learn more.

## Project aliases

Project aliases can only be read, created and deleted by a GitLab administrator.
Read through the documentation on [Project aliases](../user/project/import/index.md#project-aliases) to learn more.
