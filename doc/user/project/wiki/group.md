---
stage: Create
group: Editor
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, how-to
---

# Group wikis **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13195) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.5.

If you use GitLab groups to manage multiple projects, some of your documentation
might span multiple groups. You can create group wikis, instead of [project wikis](index.md),
to ensure all group members have the correct access permissions to contribute.
Group wikis are similar to [project wikis](index.md), with a few limitations:

- [Git LFS](../../../topics/git/lfs/index.md) is not supported.
- Group wikis are not included in [global search](../../search/advanced_search.md).
- Changes to group wikis don't show up in the [group's activity feed](../../group/index.md#group-activity-analytics).
- Group wikis are enabled by default for **(PREMIUM)** and higher tiers.
  You [can't turn them off from the GitLab user interface](https://gitlab.com/gitlab-org/gitlab/-/issues/208413).

For updates, follow [the epic that tracks feature parity with project wikis](https://gitlab.com/groups/gitlab-org/-/epics/2782).

Similar to project wikis, group members with the [Developer role](../../permissions.md#group-members-permissions)
and higher can edit group wikis. Group wiki repositories can be moved using the
[Group repository storage moves API](../../../api/group_repository_storage_moves.md).

## View a group wiki

To access a group wiki:

1. On the top bar, select **Menu > Groups** and find your group.
1. To display the wiki, either:
   - On the left sidebar, select **Wiki**.
   - On any page in the project, use the <kbd>g</kbd> + <kbd>w</kbd>
     [wiki keyboard shortcut](../../shortcuts.md).

## Export a group wiki

> Introduced in [GitLab 13.9](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53247).

Users with the [Owner role](../../permissions.md) in a group can
[import and export group wikis](../../group/settings/import_export.md) when importing
or exporting a group.

Content created in a group wiki is not deleted when an account is downgraded or a
GitLab trial ends. The group wiki data is exported whenever the group owner of
the wiki is exported.

To access the group wiki data from the export file if the feature is no longer
available, you have to:

1. Extract the [export file tarball](../../group/settings/import_export.md) with
   this command, replacing `FILENAME` with your file's name:
   `tar -xvzf FILENAME.tar.gz`
1. Browse to the `repositories` directory. This directory contains a
   [Git bundle](https://git-scm.com/docs/git-bundle) with the extension `.wiki.bundle`.
1. Clone the Git bundle into a new repository, replacing `FILENAME` with
   your bundle's name: `git clone FILENAME.wiki.bundle`

All files in the wiki are available in this Git repository.

## Related topics

- [Wiki settings for administrators](../../../administration/wikis/index.md)
- [Project wikis API](../../../api/wikis.md)
- [Group repository storage moves API](../../../api/group_repository_storage_moves.md)
- [Group wikis API](../../../api/group_wikis.md)
- [Wiki keyboard shortcuts](../../shortcuts.md#wiki-pages)
- [Epic: Feature parity with project wikis](https://gitlab.com/groups/gitlab-org/-/epics/2782)
