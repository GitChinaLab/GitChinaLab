# frozen_string_literal: true

module QA
  module Page
    module Component
      module BlobContent
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/blob/components/blob_header_filepath.vue' do
            element :file_title_content
          end

          base.view 'app/assets/javascripts/blob/components/blob_content.vue' do
            element :blob_viewer_file_content
          end

          base.view 'app/assets/javascripts/blob/components/blob_header_default_actions.vue' do
            element :default_actions_container
            element :copy_contents_button
          end

          base.view 'app/views/projects/blob/_header_content.html.haml' do
            element :file_name_content
          end

          base.view 'app/views/shared/_file_highlight.html.haml' do
            element :file_content
          end
        end

        def has_file?(name)
          has_file_name?(name)
        end

        def has_no_file?(name)
          has_no_file_name?(name)
        end

        def has_file_name?(file_name, file_number = nil)
          within_file_by_number(file_name_element, file_number) { has_text?(file_name) }
        end

        def has_no_file_name?(file_name)
          within_element(file_name_element) do
            has_no_text?(file_name)
          end
        end

        def has_file_content?(file_content, file_number = nil)
          within_file_by_number(file_content_element, file_number) { has_text?(file_content) }
        end

        def has_no_file_content?(file_content)
          within_element(file_content_element) do
            has_no_text?(file_content)
          end
        end

        def click_copy_file_contents(file_number = nil)
          within_file_by_number(:default_actions_container, file_number) { click_element(:copy_contents_button) }
        end

        private

        def file_content_element
          feature_flag_controlled_element(:refactor_blob_viewer, :blob_viewer_file_content, :file_content)
        end

        def file_name_element
          feature_flag_controlled_element(:refactor_blob_viewer, :file_title_content, :file_name_content)
        end

        def within_file_by_number(element, file_number)
          if file_number
            within_element_by_index(element, file_number - 1) { yield }
          else
            within_element(element) { yield }
          end
        end
      end
    end
  end
end
