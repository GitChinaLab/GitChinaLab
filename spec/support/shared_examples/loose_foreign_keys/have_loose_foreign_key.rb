# frozen_string_literal: true

RSpec.shared_examples 'it has loose foreign keys' do
  let(:factory_name) { nil }
  let(:table_name) { described_class.table_name }
  let(:connection) { described_class.connection }
  let(:fully_qualified_table_name) { "#{connection.current_schema}.#{table_name}" }
  let(:deleted_records) { LooseForeignKeys::DeletedRecord.where(fully_qualified_table_name: fully_qualified_table_name) }

  it 'has at least one loose foreign key definition' do
    definitions = Gitlab::Database::LooseForeignKeys.definitions_by_table[table_name]
    expect(definitions.size).to be > 0
  end

  it 'has the deletion trigger present' do
    sql = <<-SQL
    SELECT trigger_name
    FROM information_schema.triggers
    WHERE event_object_table = '#{table_name}'
    SQL

    triggers = connection.execute(sql)

    expected_trigger_name = "#{table_name}_loose_fk_trigger"
    expect(triggers.pluck('trigger_name')).to include(expected_trigger_name)
  end

  it 'records record deletions' do
    model = create(factory_name) # rubocop: disable Rails/SaveBang

    # using delete to avoid cross-database modification errors when associations with dependent option are present
    model.delete

    deleted_record = deleted_records.find_by(primary_key_value: model.id)

    expect(deleted_record).not_to be_nil
  end

  it 'cleans up record deletions' do
    model = create(factory_name) # rubocop: disable Rails/SaveBang

    expect { model.delete }.to change { deleted_records.count }.by(1)

    LooseForeignKeys::ProcessDeletedRecordsService.new(connection: connection).execute

    expect(deleted_records.status_pending.count).to be(0)
    expect(deleted_records.status_processed.count).to be(1)
  end
end

RSpec.shared_examples 'cleanup by a loose foreign key' do
  let(:foreign_key_definition) do
    foreign_keys_for_parent = Gitlab::Database::LooseForeignKeys.definitions_by_table[parent.class.table_name]
    foreign_keys_for_parent.find { |definition| definition.from_table == model.class.table_name }
  end

  def find_model
    model.class.find_by(id: model.id)
  end

  it 'deletes the model' do
    parent.delete

    expect(find_model).to be_present

    LooseForeignKeys::ProcessDeletedRecordsService.new(connection: model.connection).execute

    if foreign_key_definition.on_delete.eql?(:async_delete)
      expect(find_model).not_to be_present
    else
      expect(find_model[foreign_key_definition.column]).to eq(nil)
    end
  end
end
