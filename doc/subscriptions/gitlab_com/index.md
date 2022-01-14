---
stage: Fulfillment
group: Purchase
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# GitLab SaaS subscription **(PREMIUM SAAS)**

GitLab SaaS is the GitLab software-as-a-service offering, which is available at GitLab.com.
You don't need to install anything to use GitLab SaaS, you only need to
[sign up](https://gitlab.com/users/sign_up). When you sign up, you choose:

- [A license tier](https://about.gitlab.com/pricing/).
- [The number of seats you want](#how-seat-usage-is-determined).

All GitLab SaaS public projects, regardless of the subscription, get access to features in the **Ultimate** tier.
Qualifying open source projects also get 50,000 CI minutes and free access to the **Ultimate** tier
through the [GitLab for Open Source program](https://about.gitlab.com/solutions/open-source/).

## Obtain a GitLab SaaS subscription

To subscribe to GitLab SaaS:

1. View the [GitLab SaaS feature comparison](https://about.gitlab.com/pricing/gitlab-com/feature-comparison/)
   and decide which tier you want.
1. Create a user account for yourself by using the
   [sign up page](https://gitlab.com/users/sign_up).
1. Create a [group](../../user/group/index.md#create-a-group). You use the group to grant users access to several projects
   at once. A group is not required if you plan to have projects in a personal namespace instead.
1. Create additional users and
   [add them to the group](../../user/group/index.md#add-users-to-a-group).
1. On the left sidebar, select **Billing** and choose a tier.
1. Fill out the form to complete your purchase.

## View your GitLab SaaS subscription

Prerequisite:

- You must have the Owner [role](../../user/permissions.md) for the group.

To see the status of your GitLab SaaS subscription:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Billing**.

The following information is displayed:

| Field                       | Description |
|:----------------------------|:------------|
| **Seats in subscription**   | If this is a paid plan, represents the number of seats you've bought for this group. |
| **Seats currently in use**  | Number of seats in use. Select **See usage** to see a list of the users using these seats. |
| **Max seats used**          | Highest number of seats you've used. |
| **Seats owed**              | **Max seats used** minus **Seats in subscription**. |
| **Subscription start date** | Date your subscription started. If this is for a Free plan, it's the date you transitioned off your group's paid plan. |
| **Subscription end date**   | Date your current subscription ends. Does not apply to Free plans. |

## How seat usage is determined

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216899) in GitLab 13.5.
> - [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/292086) in GitLab 13.8 to include public
    email address.

A GitLab SaaS subscription uses a concurrent (_seat_) model. You pay for a
subscription according to the maximum number of users enabled at one time. You can
add and remove users during the subscription period, as long as the total users
at any given time doesn't exceed the subscription count.

Every user is included in seat usage, with the following exceptions:

- Users who are pending approval.
- Members with the Guest role on an Ultimate subscription.
- GitLab-created service accounts: `Ghost User` and bots
  ([`Support Bot`](../../user/project/service_desk.md#support-bot-user),
  [`Project bot users`](../../user/project/settings/project_access_tokens.md#project-bot-users), and
  so on.)

Seat usage is reviewed [quarterly or annually](../quarterly_reconciliation.md).

### View seat usage

To view a list of seats being used:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. On the **Seats** tab, view usage information.

The seat usage listing is updated live, but the usage statistics on the billing page are updated
only once per day. For this reason there can be a minor difference between the seat usage listing
and the billing page.

### Search seat usage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/262875) in GitLab 13.8.

To search users in the **Seat usage** page, enter a string in the search field. A minimum of 3
characters are required.

The search returns those users whose first name, last name, or username contain the search string.

For example:

| First name | Search string | Match ? |
|:-----------|:--------------|:--------|
| Amir       | `ami`         | Yes     |
| Amir       | `amr`         | No      |

### Export seat usage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/262877) in GitLab 14.2.

To export seat usage data as a CSV file:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Billing**.
1. Under **Seats currently in use**, select **See usage**.
1. Select **Export list**.

The generated list contains all seats being used,
and is not affected by the current search.

## Seats owed

A GitLab subscription is valid for a specific number of users.

If the number of billable users exceeds the number included in the subscription, known
as the number of **seats owed**, you must pay for the excess number of users before renewal.

For example, if you purchase a subscription for 10 users:

| Event                                              | Billable members | Maximum users |
|:---------------------------------------------------|:-----------------|:--------------|
| Ten users occupy all 10 seats.                     | 10               | 10            |
| Two new users join.                                | 12               | 12            |
| Three users leave and their accounts are removed.  | 9                | 12            |

Seats owed = 12 - 10 (Maximum users - users in subscription)

### Add users to your subscription

You can add users to your subscription at any time during the subscription period. The cost of
additional users added during the subscription period is prorated from the date of purchase through
the end of the subscription period.

To add users to a subscription:

1. Log in to the [Customers Portal](https://customers.gitlab.com/).
1. Navigate to the **Manage Purchases** page.
1. Select **Add more seats** on the relevant subscription card.
1. Enter the number of additional users.
1. Select **Proceed to checkout**.
1. Review the **Subscription Upgrade Detail**. The system lists the total price for all users on the
   system and a credit for what you've already paid. You are only be charged for the net change.
1. Select **Confirm Upgrade**.

The following is emailed to you:

- A payment receipt. You can also access this information in the Customers Portal under
  [**View invoices**](https://customers.gitlab.com/receipts).

### Remove users from your subscription

To remove a billable user from your subscription:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Billing**.
1. In the **Seats currently in use** section, select **See usage**.
1. In the row for the user you want to remove, on the right side, select the ellipsis and **Remove user**.
1. Re-type the username and select **Remove user**.

If you add a member to a group by using the [share a group with another group](../../user/group/index.md#share-a-group-with-another-group) feature, you can't remove the member by using this method. Instead, you can either:

- Remove the member from the shared group. You must be a group owner to do this.
- From the group's membership page, remove access from the entire shared group.

## Upgrade your GitLab SaaS subscription tier

To upgrade your [GitLab tier](https://about.gitlab.com/pricing/):

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Upgrade** on the relevant subscription card on the
   [Manage purchases](https://customers.gitlab.com/subscriptions) page.
1. Select the desired upgrade.
1. Confirm the active form of payment, or add a new form of payment.
1. Check the **I accept the Privacy Policy and Terms of Service** checkbox.
1. Select **Confirm purchase**.

When the purchase has been processed, you receive confirmation of your new subscription tier.

## Subscription expiry

When your subscription expires, you can continue to use paid features of GitLab for 14 days.
On the 15th day, paid features are no longer available. You can
continue to use free features.

To resume paid feature functionality, purchase a new subscription.

## Renew your GitLab SaaS subscription

To renew your subscription:

1. [Prepare for renewal by reviewing your account.](#prepare-for-renewal-by-reviewing-your-account)
1. [Renew your GitLab SaaS subscription.](#renew-or-change-a-gitlab-saas-subscription)

### Prepare for renewal by reviewing your account

Before you renew your subscription:

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the **Account details** page, verify or update the invoice contact details.
1. On the **Payment Methods** page, verify or update the credit card on file.
1. In GitLab, review your list of user accounts and [remove inactive or unwanted users](#remove-users-from-your-subscription).

### Renew or change a GitLab SaaS subscription

Starting 30 days before a subscription expires, GitLab notifies group owners
of the date of expiry with a banner in the GitLab user interface.

To renew your subscription:

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) and beneath your existing subscription, select **Renew**.
1. Review your renewal details and complete the payment process.
1. Select **Confirm purchase**.

Your updated subscription is applied to your namespace on the renewal period start date.

An invoice is generated for the renewal and available for viewing or download on the [View invoices](https://customers.gitlab.com/receipts) page.
If you have difficulty during the renewal process, contact the [Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

For details on upgrading your subscription tier, see
[Upgrade your GitLab SaaS subscription tier](#upgrade-your-gitlab-saas-subscription-tier).

### Automatic renewal

When you enable automatic renewal, the subscription automatically renews on the
expiration date without a gap in available service. An invoice is
generated for the renewal and available for viewing or download on the
[View invoices](https://customers.gitlab.com/receipts) page.

#### Enable automatic renewal

To view or change automatic subscription renewal (at the same tier as the
previous period), log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in), and:

- If a **Resume subscription** button is displayed, your subscription was canceled
  previously. Click it to resume automatic renewal.
- If a **Cancel subscription** button is displayed, your subscription is set to automatically
  renew at the end of the subscription period. Click it to cancel automatic renewal.

If you have difficulty during the renewal process, contact the
[Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

## Change the contact person for your subscription

To change the contact person who manages your subscription,
contact the GitLab [Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## CI pipeline minutes

CI pipeline minutes are the execution time for your [pipelines](../../ci/pipelines/index.md)
on GitLab shared runners. Each [GitLab SaaS tier](https://about.gitlab.com/pricing/)
includes a monthly quota of CI pipeline minutes for private and public projects in
the namespace:

| Plan     | CI pipeline minutes |
|----------|---------------------|
| Free     | 400                 |
| Premium  | 10,000              |
| Ultimate | 50,000              |

The consumption rate for CI pipeline minutes is based on the visibility of the projects:

- Private projects in the namespace consume pipeline minutes at a rate of 1 CI pipeline minute
  per 1 minute of execution time on GitLab shared runners.
- Public projects in:
  - Namespaces [created on or after 2021-07-17](https://gitlab.com/gitlab-org/gitlab/-/issues/332708)
    consume pipeline minutes at a slower rate, 1 CI pipeline minute per 125 minutes
    of execution time on GitLab shared runners. The per-minute rate for public projects
    is 0.008 CI pipeline minutes per 1 minute of execution time on GitLab shared runners.
  - Namespaces created before 2021-07-17 do not consume CI pipeline minutes.

| Plan     | CI pipeline minutes | Maximum **private** project execution time (all namespaces) | Maximum **public** project execution time (namespaces created 2021-07-17 and later) |
|----------|---------------------|-------------------------------------------------------------|-------------------------------------------------------------------------------------|
| Free     | 400                 | 400 minutes                                                 | 50,000 minutes                                                                      |
| Premium  | 10,000              | 10,000 minutes                                              | 1,250,000 minutes                                                                   |
| Ultimate | 50,000              | 50,000 minutes                                              | 6,250,000 minutes                                                                   |

Quotas apply to:

- Groups, where the minutes are shared across all members of the group, its
  subgroups, and nested projects. To view the group's usage, navigate to the group,
  then **Settings > Usage Quotas**.
- Your personal account, where the minutes are available for your personal projects.
  To view and buy personal minutes:

  1. In the top-right corner, select your avatar.
  1. Select **Edit profile**.
  1. On the left sidebar, select **[Usage Quotas](https://gitlab.com/-/profile/usage_quotas#pipelines-quota-tab)**.

Only pipeline minutes for GitLab shared runners are restricted. If you have a
specific runner set up for your projects, there is no limit to your build time on GitLab SaaS.

The available quota is reset on the first of each calendar month at midnight UTC.

When the CI minutes are depleted, an email is sent automatically to notify the owner(s)
of the namespace. You can [purchase additional CI minutes](#purchase-additional-ci-minutes),
or upgrade your account to a higher [plan](https://about.gitlab.com/pricing/).
Your own runners can still be used even if you reach your limits.

### Purchase additional CI minutes

If you're using GitLab SaaS, you can purchase additional CI minutes so your
pipelines aren't blocked after you have used all your CI minutes from your
main quota. You can find pricing for additional CI/CD minutes on the
[GitLab Pricing page](https://about.gitlab.com/pricing/). Additional minutes:

- Are only used after the shared quota included in your subscription runs out.
- Roll over month to month.

To purchase additional minutes for your personal namespace:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Usage Quotas**.
1. Select **Buy additional minutes** and GitLab redirects you to the Customers Portal.
1. Locate the subscription card that's linked to your personal namespace on GitLab SaaS, click **Buy more CI minutes**, and complete the details about the transaction.

After we process your payment, the extra CI minutes are synced to your group
namespace.

To confirm the available CI minutes for your personal projects, go to the **Usage Quotas** settings again.

The **Additional minutes** displayed now includes the purchased additional CI
minutes, plus any minutes rolled over from last month.

Be aware that:

- Extra CI minutes assigned to one group cannot be transferred to a different
  group.
- If you have used more minutes than your default quota, those minutes are
  deducted from your Additional Minutes quota immediately after your purchase of
  additional minutes.

### Purchase additional CI minutes on GitLab SaaS

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6574) in GitLab 14.5.

If you're using GitLab SaaS, you can purchase additional CI minutes so your
pipelines aren't blocked after you have used all your CI minutes from your
main quota. You can find pricing for additional CI/CD minutes on the
[GitLab Pricing page](https://about.gitlab.com/pricing/). Additional minutes:

- Are only used after the shared quota included in your subscription runs out.
- Roll over month to month.

To purchase additional minutes for your group on GitLab SaaS:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. Select **Buy additional minutes**.
1. Complete the details about the transaction.

After we process your payment, the extra CI minutes are synced to your group
namespace.

To confirm the available CI minutes, go to your group, and then select
**Settings > Usage Quotas**.

The **Additional minutes** displayed now includes the purchased additional CI
minutes, plus any minutes rolled over from last month.

Be aware that:

- Extra CI minutes assigned to one group cannot be transferred to a different
  group.
- If you have used more minutes than your default quota, those minutes are
  deducted from your Additional Minutes quota immediately after your purchase of
  additional minutes.

## Storage subscription

Projects have a free storage quota of 10 GB. To exceed this quota you must first [purchase one or
more storage subscription units](#purchase-more-storage). Each unit provides 10 GB of additional
storage per namespace. A storage subscription is renewed annually. For more details, see
[Usage Quotas](../../user/usage_quotas.md).

When the amount of purchased storage reaches zero, all projects over the free storage quota are
locked. Projects can only be unlocked by purchasing more storage subscription units.

### Purchase more storage

You can purchase storage for your personal or group namespace.

#### For your personal namespace

1. Sign in to GitLab SaaS.
1. From either your personal homepage or the group's page, go to **Settings > Usage Quotas**.
1. For each locked project, total by how much its **Usage** exceeds the free quota and purchased
   storage. You must purchase the storage increment that exceeds this total.
1. Click **Purchase more storage** and you are taken to the Customers Portal.
1. Click **Add new subscription**.
1. Scroll to **Purchase add-on subscriptions** and select **Buy storage subscription**.
1. In the **Subscription details** section select the name of the user or group from the dropdown.
1. Enter the desired quantity of storage packs.
1. In the **Billing information** section select the payment method from the dropdown.
1. Select the **Privacy Policy** and **Terms of Service** checkbox.
1. Select **Buy subscription**.
1. Sign out of the Customers Portal.
1. Switch back to the GitLab SaaS tab and refresh the page.

The **Purchased storage available** total is incremented by the amount purchased. All locked
projects are unlocked and their excess usage is deducted from the additional storage.

#### For your group namespace

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5789) in GitLab 14.6.

If you're using GitLab SaaS, you can purchase additional storage so your
pipelines aren't blocked after you have used all your storage from your
main quota. You can find pricing for additional storage on the
[GitLab Pricing page](https://about.gitlab.com/pricing/).

To purchase additional storage for your group on GitLab SaaS:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. Select **Storage** tab.
1. Select **Purchase more storage**.
1. Complete the details.

After your payment is processed, the extra storage is available for your group
namespace.

To confirm the available storage, go to your group, and then select
**Settings > Usage Quotas** and select the **Storage** tab.

The **Purchased storage available** total is incremented by the amount purchased. All locked
projects are unlocked and their excess usage is deducted from the additional storage.

## Contact Support

Learn more about:

- The tiers of [GitLab Support](https://about.gitlab.com/support/).
- [Submit a request via the Support Portal](https://support.gitlab.com/hc/en-us/requests/new).

We also encourage you to search our project trackers for known issues and
existing feature requests in the [GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues/) project.

These issues are the best avenue for getting updates on specific product plans
and for communicating directly with the relevant GitLab team members.

## Troubleshooting

### Credit card declined

If your credit card is declined when purchasing a GitLab subscription, possible reasons include:

- The credit card details provided are incorrect.
- The credit card account has insufficient funds.
- You are using a virtual credit card and it has insufficient funds, or has expired.
- The transaction exceeds the credit limit.
- The transaction exceeds the credit card's maximum transaction amount.

Check with your financial institution to confirm if any of these reasons apply. If they don't
apply, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).
