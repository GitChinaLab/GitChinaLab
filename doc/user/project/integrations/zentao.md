---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# ZenTao product integration **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/338178) in GitLab 14.5.

[ZenTao](https://www.zentao.net/) is a web-based project management platform.

## Configure ZenTao

This integration requires a ZenTao API secret key.  

Complete these steps in ZenTao:  

1. Go to your **Admin** page and select **Develop > Application**.
1. Select **Add Application**.
1. Under **Name** and **Code**, enter a name and a code for the new secret key.
1. Under **Account**, select an existing account name.
1. Select **Save**.
1. Copy the generated key to use in GitLab.

## Configure GitLab

Complete these steps in GitLab:

1. Go to your project and select **Settings > Integrations**.
1. Select **ZenTao**.
1. Turn on the **Active** toggle under **Enable Integration**.
1. Provide the ZenTao configuration information:
   - **ZenTao Web URL**: The base URL of the ZenTao instance web interface you're linking to this GitLab project (for example, `example.zentao.net`).
   - **ZenTao API URL** (optional): The base URL to the ZenTao instance API. Defaults to the Web URL value if not set.  
   - **ZenTao API token**: Use the key you generated when you [configured ZenTao](#configure-zentao).
   - **ZenTao Product ID**: To display issues from a single ZenTao product in a given GitLab project. The Product ID can be found in the ZenTao product page under **Settings > Overview**.

   ![ZenTao settings page](img/zentao_product_id.png)

1. To verify the ZenTao connection is working, select **Test settings**.
1. Select **Save changes**.
