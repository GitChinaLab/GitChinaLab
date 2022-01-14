# frozen_string_literal: true

module QA
  module Page
    module Component
      module Issuable
        module Common
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/issues/show/components/title.vue' do
              element :edit_button
              element :title, required: true
            end

            base.view 'app/assets/javascripts/issues/show/components/fields/title.vue' do
              element :title_input
            end

            base.view 'app/assets/javascripts/issues/show/components/fields/description.vue' do
              element :description_textarea
            end

            base.view 'app/assets/javascripts/issues/show/components/edit_actions.vue' do
              element :save_button
              element :delete_button
            end
          end
        end
      end
    end
  end
end
