# frozen_string_literal: true

module QA
  module Flow
    module Purchase
      include QA::Support::Helpers::Plan

      module_function

      def upgrade_subscription(plan: PREMIUM)
        Page::Group::Menu.perform(&:go_to_billing)
        Gitlab::Page::Group::Settings::Billing.perform do |billing|
          billing.send("upgrade_to_#{plan[:name].downcase}")
        end

        Gitlab::Page::Subscriptions::New.perform do |new_subscription|
          new_subscription.continue_to_billing

          fill_in_customer_info
          fill_in_payment_info

          new_subscription.confirm_purchase
        end
      end

      def purchase_ci_minutes(quantity: 1)
        Page::Group::Menu.perform(&:go_to_usage_quotas)
        Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
          usage_quota.pipeline_tab
          usage_quota.buy_ci_minutes
        end

        Gitlab::Page::Subscriptions::New.perform do |ci_minutes|
          ci_minutes.quantity = quantity
          ci_minutes.continue_to_billing

          fill_in_customer_info
          fill_in_payment_info

          ci_minutes.confirm_purchase
        end
      end

      def purchase_storage(quantity: 1)
        Page::Group::Menu.perform(&:go_to_usage_quotas)
        Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
          usage_quota.storage_tab
          usage_quota.buy_storage
        end

        Gitlab::Page::Subscriptions::New.perform do |storage|
          storage.quantity = quantity
          storage.continue_to_billing

          fill_in_customer_info
          fill_in_payment_info

          storage.confirm_purchase
        end
      end

      def fill_in_customer_info
        Gitlab::Page::Subscriptions::New.perform do |subscription|
          subscription.country = user_billing_info[:country]
          subscription.street_address_1 = user_billing_info[:address_1]
          subscription.street_address_2 = user_billing_info[:address_2]
          subscription.city = user_billing_info[:city]
          subscription.state = user_billing_info[:state]
          subscription.zip_code = user_billing_info[:zip]
          subscription.continue_to_payment
        end
      end

      def fill_in_payment_info
        Gitlab::Page::Subscriptions::New.perform do |subscription|
          subscription.name_on_card = credit_card_info[:name]
          subscription.card_number = credit_card_info[:number]
          subscription.expiration_month = credit_card_info[:month]
          subscription.expiration_year = credit_card_info[:year]
          subscription.cvv = credit_card_info[:cvv]
          subscription.review_your_order
        end
      end

      def credit_card_info
        {
          name: 'QA Test',
          number: '4111111111111111',
          month: '01',
          year: '2025',
          cvv: '232'
        }.freeze
      end

      def user_billing_info
        {
          country: 'United States of America',
          address_1: 'Address 1',
          address_2: 'Address 2',
          city: 'San Francisco',
          state: 'California',
          zip: '94102'
        }.freeze
      end
    end
  end
end
