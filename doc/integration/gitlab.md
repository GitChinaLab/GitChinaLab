---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Integrate your server with GitLab.com **(FREE SELF)**

Import projects from GitLab.com and login to your GitLab instance with your GitLab.com account.

To enable the GitLab.com OmniAuth provider you must register your application with GitLab.com.
GitLab.com generates an application ID and secret key for you to use.

1. Sign in to GitLab.com.
1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Applications**.
1. Provide the required details for **Add new application**.
   - Name: This can be anything. Consider something like `<Organization>'s GitLab` or `<Your Name>'s GitLab` or something else descriptive.
   - Redirect URI:

   ```plaintext
   http://your-gitlab.example.com/import/gitlab/callback
   http://your-gitlab.example.com/users/auth/gitlab/callback
   ```

   The first link is required for the importer and second for the authorization.

1. Select **Save application**.
1. You should now see an **Application ID** and **Secret**. Keep this page open as you continue
   configuration.
1. On your GitLab server, open the configuration file.

   For Omnibus package:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H editor config/gitlab.yml
   ```

1. See [Configure initial settings](omniauth.md#configure-initial-settings) for initial settings.
1. Add the provider configuration:

   For Omnibus installations authenticating against **GitLab.com**:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       # label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "api" }
     }
   ]
   ```

   Or, for Omnibus installations authenticating against a different GitLab instance:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "api", client_options: { site: "https://gitlab.example.com/api/v4" } }
     }
   ]
   ```

   For installations from source authenticating against **GitLab.com**:

   ```yaml
   - { name: 'gitlab',
       # label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { scope: 'api' } }
   ```

   Or, for installations from source to authenticate against a different GitLab instance:

   ```yaml
   - { name: 'gitlab',
       label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { scope: 'api', "client_options": { "site": 'https://gitlab.example.com/api/v4' } }
   ```

1. Change `'YOUR_APP_ID'` to the Application ID from the GitLab.com application page.
1. Change `'YOUR_APP_SECRET'` to the secret from the GitLab.com application page.
1. Save the configuration file.
1. Based on how GitLab was installed, implement these changes by using
   the appropriate method:

   - Omnibus GitLab: [reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure).
   - Source: [restart GitLab](../administration/restart_gitlab.md#installations-from-source).

On the sign-in page, there should now be a GitLab.com icon following the
regular sign-in form. Select the icon to begin the authentication process.
GitLab.com asks the user to sign in and authorize the GitLab application. If
everything goes well, the user is returned to your GitLab instance and is
signed in.
