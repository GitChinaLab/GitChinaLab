# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::ProjectEntitiesPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:destination_group) { create(:group) }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      group: destination_group,
      destination_namespace: destination_group.full_path
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:extracted_data) do
    BulkImports::Pipeline::ExtractedData.new(data: {
      'name' => 'project',
      'full_path' => 'group/project'
    })
  end

  subject { described_class.new(context) }

  describe '#run' do
    before do
      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(extracted_data)
      end

      destination_group.add_owner(user)
    end

    it 'creates project entity' do
      expect { subject.run }.to change(BulkImports::Entity, :count).by(1)

      project_entity = BulkImports::Entity.last

      expect(project_entity.source_type).to eq('project_entity')
      expect(project_entity.source_full_path).to eq('group/project')
      expect(project_entity.destination_name).to eq('project')
      expect(project_entity.destination_namespace).to eq(destination_group.full_path)
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor).to eq(
        klass: BulkImports::Common::Extractors::GraphqlExtractor,
        options: {
          query: BulkImports::Groups::Graphql::GetProjectsQuery
        }
      )
    end

    it 'has transformers' do
      expect(described_class.transformers).to contain_exactly(
        { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil }
      )
    end
  end
end
