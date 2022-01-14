# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::PipelineSchedulesPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_name: 'My Destination Project',
      destination_namespace: group.full_path
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:schedule_attributes) { {} }
  let(:schedule) do
    {
      'description' => 'test pipeline schedule',
      'cron' => '1 1 1 1 1',
      'cron_timezone' => 'UTC',
      'ref' => 'testref',
      'created_at' => '2016-06-13T15:02:47.967Z',
      'updated_at' => '2016-06-14T15:02:47.967Z'
    }.merge(schedule_attributes)
  end

  subject(:pipeline) { described_class.new(context) }

  before do
    group.add_owner(user)

    allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
      allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [schedule]))
    end

    pipeline.run
  end

  it 'imports schedule into destination project' do
    expect(project.pipeline_schedules.count).to eq(1)
    pipeline_schedule = project.pipeline_schedules.first
    schedule.each do |k, v|
      expect(pipeline_schedule.send(k)).to eq(v)
    end
  end

  context 'is active' do
    let(:schedule_attributes) { { 'active' => true } }

    it 'imports the schedule but active is false' do
      expect(project.pipeline_schedules.first.active).to be_falsey
    end
  end
end
