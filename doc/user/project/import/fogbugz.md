---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Import your project from FogBugz to GitLab **(FREE)**

Using the importer, you can import your FogBugz project to GitLab.com
or to your self-managed GitLab instance.

The importer imports all of your cases and comments with the original
case numbers and timestamps. You can also map FogBugz users to GitLab
users.

To import your project from FogBugz:

1. Sign in to GitLab.
1. On the top bar, select **New** (**{plus}**).
1. Select **New project/repository**.
1. Select **Import project**.
1. Select **FogBugz**.
1. Enter your FogBugz URL, email address, and password.
1. Create a mapping from FogBugz users to GitLab users.
   ![User Map](img/fogbugz_import_user_map.png)
1. For the projects you want to import, select **Import**.
   ![Import Project](img/fogbugz_import_select_project.png)
1. After the import finishes, select the link to go to the project
   dashboard. Follow the directions to push your existing repository.
   ![Finished](img/fogbugz_import_finished.png)
