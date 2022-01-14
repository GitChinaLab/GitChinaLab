# frozen_string_literal: true

module GlobalIDDeprecationHelpers
  def stub_global_id_deprecations(*deprecations)
    old_name_map = deprecations.index_by(&:old_model_name)
    new_name_map = deprecations.index_by(&:new_model_name)
    old_graphql_name_map = deprecations.index_by { |d| Types::GlobalIDType.model_name_to_graphql_name(d.old_model_name) }

    stub_const('Gitlab::GlobalId::Deprecations::OLD_NAME_MAP', old_name_map)
    stub_const('Gitlab::GlobalId::Deprecations::NEW_NAME_MAP', new_name_map)
    stub_const('Gitlab::GlobalId::Deprecations::OLD_GRAPHQL_NAME_MAP', old_graphql_name_map)
  end
end
