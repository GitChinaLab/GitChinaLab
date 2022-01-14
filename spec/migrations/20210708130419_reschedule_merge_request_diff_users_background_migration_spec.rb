# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RescheduleMergeRequestDiffUsersBackgroundMigration, :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    before do
      allow(described_class::MergeRequestDiff)
        .to receive(:minimum)
        .with(:id)
        .and_return(42)

      allow(described_class::MergeRequestDiff)
        .to receive(:maximum)
        .with(:id)
        .and_return(85_123)
    end

    it 'deletes existing background migration job records' do
      args = [150_000, 300_000]

      Gitlab::Database::BackgroundMigrationJob
        .create!(class_name: described_class::MIGRATION_NAME, arguments: args)

      migration.up

      found = Gitlab::Database::BackgroundMigrationJob
        .where(class_name: described_class::MIGRATION_NAME, arguments: args)
        .count

      expect(found).to eq(0)
    end

    it 'schedules the migrations in batches' do
      expect(migration)
        .to receive(:migrate_in)
        .ordered
        .with(2.minutes.to_i, described_class::MIGRATION_NAME, [42, 40_042])

      expect(migration)
        .to receive(:migrate_in)
        .ordered
        .with(4.minutes.to_i, described_class::MIGRATION_NAME, [40_042, 80_042])

      expect(migration)
        .to receive(:migrate_in)
        .ordered
        .with(6.minutes.to_i, described_class::MIGRATION_NAME, [80_042, 120_042])

      migration.up
    end

    it 'creates rows to track the background migration jobs' do
      expect(Gitlab::Database::BackgroundMigrationJob)
        .to receive(:create!)
        .ordered
        .with(class_name: described_class::MIGRATION_NAME, arguments: [42, 40_042])

      expect(Gitlab::Database::BackgroundMigrationJob)
        .to receive(:create!)
        .ordered
        .with(class_name: described_class::MIGRATION_NAME, arguments: [40_042, 80_042])

      expect(Gitlab::Database::BackgroundMigrationJob)
        .to receive(:create!)
        .ordered
        .with(class_name: described_class::MIGRATION_NAME, arguments: [80_042, 120_042])

      migration.up
    end
  end
end
