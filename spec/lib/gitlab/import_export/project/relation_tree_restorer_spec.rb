# frozen_string_literal: true

# This spec is a lightweight version of:
#   * project/tree_restorer_spec.rb
#
# In depth testing is being done in the above specs.
# This spec tests that restore project works
# but does not have 100% relation coverage.

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::RelationTreeRestorer do
  let_it_be(:importable, reload: true) do
    create(:project, :builds_enabled, :issues_disabled, name: 'project', path: 'project')
  end

  include_context 'relation tree restorer shared context' do
    let(:importable_name) { 'project' }
  end

  let(:reader) { Gitlab::ImportExport::Reader.new(shared: shared) }
  let(:relation_tree_restorer) do
    described_class.new(
      user:                  user,
      shared:                shared,
      relation_reader:       relation_reader,
      object_builder:        Gitlab::ImportExport::Project::ObjectBuilder,
      members_mapper:        members_mapper,
      relation_factory:      Gitlab::ImportExport::Project::RelationFactory,
      reader:                reader,
      importable:            importable,
      importable_path:       'project',
      importable_attributes: attributes
    )
  end

  subject { relation_tree_restorer.restore }

  shared_examples 'import project successfully' do
    describe 'imported project' do
      it 'has the project attributes and relations', :aggregate_failures do
        expect(subject).to eq(true)

        project = Project.find_by_path('project')

        expect(project.description).to eq('Nisi et repellendus ut enim quo accusamus vel magnam.')
        expect(project.labels.count).to eq(3)
        expect(project.boards.count).to eq(1)
        expect(project.project_feature).not_to be_nil
        expect(project.custom_attributes.count).to eq(2)
        expect(project.project_badges.count).to eq(2)
        expect(project.snippets.count).to eq(1)
      end
    end
  end

  shared_examples 'logging of relations creation' do
    context 'when log_import_export_relation_creation feature flag is enabled' do
      before do
        stub_feature_flags(log_import_export_relation_creation: group)
      end

      it 'logs top-level relation creation' do
        expect(shared.logger)
          .to receive(:info)
          .with(hash_including(message: '[Project/Group Import] Created new object relation'))
          .at_least(:once)

        subject
      end
    end

    context 'when log_import_export_relation_creation feature flag is disabled' do
      before do
        stub_feature_flags(log_import_export_relation_creation: false)
      end

      it 'does not log top-level relation creation' do
        expect(shared.logger)
          .to receive(:info)
          .with(hash_including(message: '[Project/Group Import] Created new object relation'))
          .never

        subject
      end
    end
  end

  context 'with legacy reader' do
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/complex/project.json' }
    let(:relation_reader) do
      Gitlab::ImportExport::Json::LegacyReader::File.new(
        path,
        relation_names: reader.project_relation_names,
        allowed_path: 'project'
      )
    end

    let(:attributes) { relation_reader.consume_attributes('project') }

    it_behaves_like 'import project successfully'

    context 'with logging of relations creation' do
      let_it_be(:group) { create(:group).tap { |g| g.add_maintainer(user) } }
      let_it_be(:importable) do
        create(:project, :builds_enabled, :issues_disabled, name: 'project', path: 'project', group: group)
      end

      include_examples 'logging of relations creation'
    end
  end

  context 'with ndjson reader' do
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/complex/tree' }
    let(:relation_reader) { Gitlab::ImportExport::Json::NdjsonReader.new(path) }

    it_behaves_like 'import project successfully'

    context 'when inside a group' do
      let_it_be(:group) do
        create(:group, :disabled_and_unoverridable).tap { |g| g.add_maintainer(user) }
      end

      before do
        importable.update!(shared_runners_enabled: false, group: group)
      end

      it_behaves_like 'import project successfully'
    end
  end

  context 'with invalid relations' do
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/project_with_invalid_relations/tree' }
    let(:relation_reader) { Gitlab::ImportExport::Json::NdjsonReader.new(path) }

    it 'logs the invalid relation and its errors' do
      expect(shared.logger)
        .to receive(:warn)
        .with(
          error_messages: "Title can't be blank. Title is invalid",
          message: '[Project/Group Import] Invalid object relation built',
          relation_class: 'ProjectLabel',
          relation_index: 0,
          relation_key: 'labels'
        ).once

      relation_tree_restorer.restore
    end
  end
end
