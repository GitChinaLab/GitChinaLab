---
stage: Manage
group: Import
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
---

# Project import/export **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/3050) in GitLab 8.9.
> - From GitLab 10.0, administrators can disable the project export option on the GitLab instance.

Existing projects running on any GitLab instance or GitLab.com can be exported with all their related
data and be moved into a new GitLab instance.

The **GitLab import/export** button is displayed if the project import option is enabled.

See also:

- [Project import/export API](../../../api/project_import_export.md)
- [Project import/export administration Rake tasks](../../../administration/raketasks/project_import_export.md) **(FREE SELF)**
- [Group import/export](../../group/settings/import_export.md)
- [Group import/export API](../../../api/group_import_export.md)

To set up a project import/export:

  1. On the top bar, go to **Menu > Admin > Settings > General > Visibility and access controls**.
  1. Scroll to **Import sources**.
  1. Enable the desired **Import sources**.

## Important notes

Note the following:

- Before you can import a project, you must export the data first.
  See [Export a project and its data](#export-a-project-and-its-data)
  for how you can export a project through the UI.
- Imports from a newer version of GitLab are not supported.
  The Importing GitLab version must be greater than or equal to the Exporting GitLab version.
- Imports fail unless the import and export GitLab instances are
  compatible as described in the [Version history](#version-history).
- Exports are generated in your configured `shared_path`, a temporary shared directory,
  and are moved to your configured `uploads_directory`. Every 24 hours, a specific worker deletes these export files.
- Group members are exported as project members, as long as the user has
  a maintainer or administrator role in the group where the exported project lives.
- Project members with the [Owner role](../../permissions.md) are imported as Maintainers.
- Imported users can be mapped by their public email on self-managed instances, if an administrative user (not an owner) does the import.
  The public email is not set by default. Users must [set it in their profiles](../../profile/index.md#set-your-public-email)
  for mapping to work correctly. Additionally, the user must be an existing member of the namespace,
  or the user can be added as a member of the project for contributions to be mapped.
  Otherwise, a supplementary comment is left to mention that the original author and
  the MRs, notes, or issues are owned by the importer.
  - For project migration imports performed over GitLab.com Groups, preserving author information is
    possible through a [professional services engagement](https://about.gitlab.com/services/migration/).
- If an imported project contains merge requests originating from forks,
  then new branches associated with such merge requests are created
  in a project during the import/export. Thus, the number of branches
  in the exported project could be bigger than in the original project.
- Deploy keys allowed to push to protected branches are not exported. Therefore,
  you must recreate this association by first enabling these deploy keys in your
  imported project and then updating your protected branches accordingly.

## Version history

### 14.0+

In GitLab 14.0, the JSON format is no longer supported for project and group exports. To allow for a
transitional period, you can still import any JSON exports. The new format for imports and exports
is NDJSON.

### 13.0+

Starting with GitLab 13.0, GitLab can import bundles that were exported from a different GitLab deployment.
This ability is limited to two previous GitLab [minor](../../../policy/maintenance.md#versioning)
releases, which is similar to our process for [Security Releases](../../../policy/maintenance.md#security-releases).

For example:

| Current version | Can import bundles exported from |
|-----------------|----------------------------------|
| 13.0            | 13.0, 12.10, 12.9                |
| 13.1            | 13.1, 13.0, 12.10                |

### 12.x

Prior to 13.0 this was a defined compatibility table:

| Exporting GitLab version   | Importing GitLab version   |
| -------------------------- | -------------------------- |
| 11.7 to 12.10              | 11.7 to 12.10              |
| 11.1 to 11.6               | 11.1 to 11.6               |
| 10.8 to 11.0               | 10.8 to 11.0               |
| 10.4 to 10.7               | 10.4 to 10.7               |
| 10.3                       | 10.3                       |
| 10.0 to 10.2               | 10.0 to 10.2               |
| 9.4 to 9.6                 | 9.4 to 9.6                 |
| 9.2 to 9.3                 | 9.2 to 9.3                 |
| 8.17 to 9.1                | 8.17 to 9.1                |
| 8.13 to 8.16               | 8.13 to 8.16               |
| 8.12                       | 8.12                       |
| 8.10.3 to 8.11             | 8.10.3 to 8.11             |
| 8.10.0 to 8.10.2           | 8.10.0 to 8.10.2           |
| 8.9.5 to 8.9.11            | 8.9.5 to 8.9.11            |
| 8.9.0 to 8.9.4             | 8.9.0 to 8.9.4             |

Projects can be exported and imported only between versions of GitLab with matching Import/Export versions.

For example, 8.10.3 and 8.11 have the same Import/Export version (0.1.3)
and the exports between them are compatible.

## Between CE and EE

You can export projects from the [Community Edition to the Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/) and vice versa.
This assumes [version history](#version-history) requirements are met.

If you're exporting a project from the Enterprise Edition to the Community Edition, you may lose data that is retained only in the Enterprise Edition. For more information, see [downgrading from EE to CE](../../../index.md).

## Exported contents

The following items are exported:

- Project and wiki repositories
- Project uploads
- Project configuration, excluding integrations
- Issues with comments, merge requests with diffs and comments, labels, milestones, snippets, time tracking,
  and other project entities
- Design Management files and data
- LFS objects
- Issue boards
- Pipelines history
- Push Rules
- Awards

The following items are **not** exported:

- Build traces and artifacts
- Container registry images
- CI/CD variables
- Pipeline triggers
- Webhooks
- Any encrypted tokens
- Merge Request Approvers
- Repository size limits

These content rules also apply to creating projects from templates on the
[group](../../group/custom_project_templates.md)
or [instance](../../admin_area/custom_project_templates.md)
levels, because the same export and import mechanisms are used.

NOTE:
For more details on the specific data persisted in a project export, see the
[`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml) file.

## Export a project and its data

Full project export functionality is limited to project maintainers and owners.
You can configure such functionality through [project settings](index.md):

To export a project and its data, follow these steps:

1. Go to your project's homepage.

1. Select **Settings** in the sidebar.

1. Scroll down and expand the **Advanced** section.

1. Scroll down to find the **Export project** button:

   ![Export button](img/import_export_export_button.png)

1. After the export is generated, you should receive an email with a link to
   download the file:

   ![Email download link](img/import_export_mail_link.png)

1. Alternatively, you can come back to the project settings and download the
   file from there, or generate a new export. After the file is available, the page
   should show the **Download export** button:

   ![Download export](img/import_export_download_export.png)

## Import the project

> Default maximum import file size [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50 MB to unlimited in GitLab 13.8.

WARNING:
Only import projects from sources you trust. If you import a project from an untrusted source, it
may be possible for an attacker to steal your sensitive data.

1. The GitLab project import feature is the first import option when creating a
   new project. Select **GitLab export**:

   ![New project](img/import_export_new_project.png)

1. Enter your project name and URL. Then select the file you exported previously:

   ![Select file](img/import_export_select_file.png)

1. Select **Import project** to begin importing. Your newly imported project
   page appears shortly.

NOTE:
If use of the `Internal` visibility level
[is restricted](../../../public_access/public_access.md#restrict-use-of-public-or-internal-projects),
all imported projects are given the visibility of `Private`.

The maximum import file size can be set by the Administrator, and the default is `0` (unlimited).
As an administrator, you can modify the maximum import file size. To do so, use the `max_import_size` option in the [Application settings API](../../../api/settings.md#change-application-settings) or the [Admin Area UI](../../admin_area/settings/account_and_limit_settings.md).

### Project import status

You can query an import through the [Project import/export API](../../../api/project_import_export.md#import-status).
As described in the API documentation, the query may return an import error or exceptions.

### Import large projects **(FREE SELF)**

If you have a larger project, consider using a Rake task, as described in our [developer documentation](../../../development/import_project.md#importing-via-a-rake-task).

## Rate Limits

To help avoid abuse, by default, users are rate limited to:

| Request Type     | Limit                                    |
| ---------------- | ---------------------------------------- |
| Export           | 6 projects per minute                |
| Download export  | 1 download per group per minute  |
| Import           | 6 projects per minute                |

GitLab.com may have [different settings](../../gitlab_com/index.md#importexport) from the defaults.

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](../import/index.md#automate-group-and-project-import).

## Troubleshooting

### Project fails to import due to mismatch

If the [shared runners enablement](../../../ci/runners/runners_scope.md#enable-shared-runners)
does not match between the exported project, and the project import, the project fails to import.
Review [issue 276930](https://gitlab.com/gitlab-org/gitlab/-/issues/276930), and either:

- Ensure shared runners are enabled in both the source and destination projects.
- Disable shared runners on the parent group when you import the project.

### Import workarounds for large repositories

[Maximum import size limitations](#import-the-project)
can prevent an import from being successful. If changing the import limits is not possible, you can
try one of the workarounds listed here.

#### Workaround option 1

The following local workflow can be used to temporarily
reduce the repository size for another import attempt:

1. Create a temporary working directory from the export:

    ```shell
    EXPORT=<filename-without-extension>

    mkdir "$EXPORT"
    tar -xf "$EXPORT".tar.gz --directory="$EXPORT"/
    cd "$EXPORT"/
    git clone project.bundle

    # Prevent interference with recreating an importable file later
    mv project.bundle ../"$EXPORT"-original.bundle
    mv ../"$EXPORT".tar.gz ../"$EXPORT"-original.tar.gz

    git switch --create smaller-tmp-main
    ```

1. To reduce the repository size, work on this `smaller-tmp-main` branch:
   [identify and remove large files](../repository/reducing_the_repo_size_using_git.md)
   or [interactively rebase and fixup](../../../topics/git/git_rebase.md#interactive-rebase)
   to reduce the number of commits.

    ```shell
    # Reduce the .git/objects/pack/ file size
    cd project
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive

    # Prepare recreating an importable file
    git bundle create ../project.bundle <default-branch-name>
    cd ..
    mv project/ ../"$EXPORT"-project
    cd ..

    # Recreate an importable file
    tar -czf "$EXPORT"-smaller.tar.gz --directory="$EXPORT"/ .
    ```

1. Import this new, smaller file into GitLab.
1. In a full clone of the original repository,
   use `git remote set-url origin <new-url> && git push --force --all`
   to complete the import.
1. Update the imported repository's
   [branch protection rules](../protected_branches.md) and
   its [default branch](../repository/branches/default.md), and
   delete the temporary, `smaller-tmp-main` branch, and
   the local, temporary data.

#### Workaround option 2

Rather than attempting to push all changes at once, this workaround:

- Separates the project import from the Git Repository import
- Incrementally pushes the repository to GitLab

1. Make a local clone of the repository to migrate. In a later step, you push this clone outside of
   the project export.
1. Download the export and remove the `project.bundle` (which contains the Git repository):

   ```shell
   tar -czvf new_export.tar.gz --exclude='project.bundle' @old_export.tar.gz
   ```

1. Import the export without a Git repository. It asks you to confirm to import without a
   repository.
1. Save this bash script as a file and run it after adding the appropriate origin.

   ```shell
   #!/bin/sh

   # ASSUMPTIONS:
   # - The GitLab location is "origin"
   # - The default branch is "main"
   # - This will attempt to push in chunks of 500MB (dividing the total size by 500MB).
   #   Decrease this size to push in smaller chunks if you still receive timeouts.

   git gc
   SIZE=$(git count-objects -v 2> /dev/null | grep size-pack | awk '{print $2}')

   # Be conservative... and try to push 2GB at a time
   # (given this assumes each commit is the same size - which is wrong)
   BATCHES=$(($SIZE / 500000))
   TOTAL_COMMITS=$(git rev-list --count HEAD)
   if (( BATCHES > TOTAL_COMMITS )); then
       BATCHES=$TOTAL_COMMITS
   fi

   INCREMENTS=$(( ($TOTAL_COMMITS / $BATCHES) - 1 ))

   for (( BATCH=BATCHES; BATCH>=1; BATCH-- ))
   do
     COMMIT_NUM=$(( $BATCH - $INCREMENTS ))
     COMMIT_SHA=$(git log -n $COMMIT_NUM --format=format:%H | tail -1)
     git push -u origin ${COMMIT_SHA}:refs/heads/main
   done
   git push -u origin main
   git push -u origin -—all
   git push -u origin -—tags
   ```

### Manually execute export steps

Exports sometimes fail without giving enough information to troubleshoot. In these cases, it can be
helpful to [execute the export process manually within rails](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/uncategorized/project-export.md#export-a-project-via-rails-console).
Execute each line individually, rather than pasting the entire block at once, so you can see any
errors each command returns.

```shell
u = User.find_by_username('someuser')
p = Project.find_by_full_path('some/project')
e = Projects::ImportExport::ExportService.new(p,u)

e.send(:version_saver).send(:save)
e.send(:avatar_saver).send(:save)
e.send(:project_tree_saver).send(:save)
e.send(:uploads_saver).send(:save)
e.send(:wiki_repo_saver).send(:save)
e.send(:lfs_saver).send(:save)
e.send(:snippets_repo_saver).send(:save)
e.send(:design_repo_saver).send(:save)

s = Gitlab::ImportExport::Saver.new(exportable: p, shared:p.import_export_shared)
s.send(:compress_and_save)
s.send(:save_upload)
```
