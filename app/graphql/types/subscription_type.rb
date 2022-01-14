# frozen_string_literal: true

module Types
  class SubscriptionType < ::Types::BaseObject
    graphql_name 'Subscription'

    field :issuable_assignees_updated, subscription: Subscriptions::IssuableUpdated, null: true,
          description: 'Triggered when the assignees of an issuable are updated.'

    field :issue_crm_contacts_updated, subscription: Subscriptions::IssuableUpdated, null: true,
          description: 'Triggered when the crm contacts of an issuable are updated.'
  end
end
