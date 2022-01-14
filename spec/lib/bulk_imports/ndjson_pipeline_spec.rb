# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::NdjsonPipeline do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:klass) do
    Class.new do
      include BulkImports::NdjsonPipeline

      relation_name 'test'

      attr_reader :portable, :current_user

      def initialize(portable, user)
        @portable = portable
        @current_user = user
      end
    end
  end

  before do
    stub_const('NdjsonPipelineClass', klass)
  end

  subject { NdjsonPipelineClass.new(group, user) }

  it 'marks pipeline as ndjson' do
    expect(NdjsonPipelineClass.ndjson_pipeline?).to eq(true)
  end

  describe '#deep_transform_relation!' do
    it 'transforms relation hash' do
      transformed = subject.deep_transform_relation!({}, 'test', {}) do |key, hash|
        hash.merge(relation_key: key)
      end

      expect(transformed[:relation_key]).to eq('test')
    end

    context 'when subrelations is an array' do
      it 'transforms each element of the array' do
        relation_hash = {
          'key' => 'value',
          'labels' => [
            { 'title' => 'label 1' },
            { 'title' => 'label 2' },
            { 'title' => 'label 3' }
          ]
        }
        relation_definition = { 'labels' => {} }

        transformed = subject.deep_transform_relation!(relation_hash, 'test', relation_definition) do |key, hash|
          hash.merge(relation_key: key)
        end

        transformed['labels'].each do |label|
          expect(label[:relation_key]).to eq('group_labels')
        end
      end
    end

    context 'when subrelation is a hash' do
      it 'transforms subrelation hash' do
        relation_hash = {
          'key' => 'value',
          'label' => { 'title' => 'label' }
        }
        relation_definition = { 'label' => {} }

        transformed = subject.deep_transform_relation!(relation_hash, 'test', relation_definition) do |key, hash|
          hash.merge(relation_key: key)
        end

        expect(transformed['label'][:relation_key]).to eq('group_label')
      end
    end

    context 'when subrelation is nil' do
      it 'removes subrelation' do
        relation_hash = {
          'key' => 'value',
          'label' => { 'title' => 'label' }
        }
        relation_definition = { 'label' => {} }

        transformed = subject.deep_transform_relation!(relation_hash, 'test', relation_definition) do |key, hash|
          if key == 'group_label'
            nil
          else
            hash
          end
        end

        expect(transformed['label']).to be_nil
      end
    end
  end

  describe '#transform' do
    it 'calls relation factory' do
      hash = { key: :value }
      data = [hash, 1]
      user = double
      config = double(relation_excluded_keys: nil, top_relation_tree: [])
      import_double = instance_double(BulkImport, id: 1)
      entity_double = instance_double(BulkImports::Entity, id: 2)
      context = double(portable: group, current_user: user, import_export_config: config, bulk_import: import_double, entity: entity_double)
      allow(subject).to receive(:import_export_config).and_return(config)
      allow(subject).to receive(:context).and_return(context)
      relation_object = double

      expect(Gitlab::ImportExport::Group::RelationFactory)
        .to receive(:create)
        .with(
          relation_index: 1,
          relation_sym: :test,
          relation_hash: hash,
          importable: group,
          members_mapper: instance_of(BulkImports::UsersMapper),
          object_builder: Gitlab::ImportExport::Group::ObjectBuilder,
          user: user,
          excluded_keys: nil
        )
        .and_return(relation_object)
      expect(relation_object).to receive(:assign_attributes).with(group: group)

      subject.transform(context, data)
    end

    context 'when data is nil' do
      before do
        expect(Gitlab::ImportExport::Group::RelationFactory).not_to receive(:create)
      end

      it 'returns' do
        expect(subject.transform(nil, nil)).to be_nil
      end

      context 'when relation hash is nil' do
        it 'returns' do
          expect(subject.transform(nil, [nil, 0])).to be_nil
        end
      end
    end
  end

  describe '#load' do
    context 'when object is not persisted' do
      it 'saves the object' do
        object = double(persisted?: false)

        expect(object).to receive(:save!)

        subject.load(nil, object)
      end
    end

    context 'when object is missing' do
      it 'returns' do
        expect(subject.load(nil, nil)).to be_nil
      end
    end
  end

  describe '#relation_class' do
    context 'when relation name is pluralized' do
      it 'returns constantized class' do
        expect(subject.relation_class('MergeRequest::Metrics')).to eq(MergeRequest::Metrics)
      end
    end

    context 'when relation name is singularized' do
      it 'returns constantized class' do
        expect(subject.relation_class('Badge')).to eq(Badge)
      end
    end
  end

  describe '#relation_key_override' do
    context 'when portable is group' do
      it 'returns group relation name override' do
        expect(subject.relation_key_override('labels')).to eq('group_labels')
      end
    end

    context 'when portable is project' do
      subject { NdjsonPipelineClass.new(project, user) }

      it 'returns group relation name override' do
        expect(subject.relation_key_override('labels')).to eq('project_labels')
      end
    end
  end

  describe '#relation_factory' do
    context 'when portable is group' do
      it 'returns group relation factory' do
        expect(subject.relation_factory).to eq(Gitlab::ImportExport::Group::RelationFactory)
      end
    end

    context 'when portable is project' do
      subject { NdjsonPipelineClass.new(project, user) }

      it 'returns project relation factory' do
        expect(subject.relation_factory).to eq(Gitlab::ImportExport::Project::RelationFactory)
      end
    end
  end
end
