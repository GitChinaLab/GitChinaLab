# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class <%= migration_class_name %> < Gitlab::Database::Migration[<%= Gitlab::Database::Migration.current_version %>]
  # When using the methods "add_concurrent_index" or "remove_concurrent_index"
  # you must disable the use of transactions
  # as these methods can not run in an existing transaction.
  # When using "add_concurrent_index" or "remove_concurrent_index" methods make sure
  # that either of them is the _only_ method called in the migration,
  # any other changes should go in a separate migration.
  # This ensures that upon failure _only_ the index creation or removing fails
  # and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  # disable_ddl_transaction!

  def change
    create_table :<%= table_name %> do |t|
<% attributes.each do |attribute| -%>
<% if attribute.password_digest? -%>
      t.string :password_digest<%= attribute.inject_options %>
<% else -%>
      t.<%= attribute.type %> :<%= attribute.name %><%= attribute.inject_options %>
<% end -%>
<% end -%>
<% if options[:timestamps] %>
      t.timestamps null: false
<% end -%>
    end
<% attributes_with_index.each do |attribute| -%>
    add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
<% end -%>
  end
end
