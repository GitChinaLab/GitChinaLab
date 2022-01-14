# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Loaders::GroupLoader do
  describe '#load' do
    let_it_be(:user) { create(:user) }
    let_it_be(:bulk_import) { create(:bulk_import, user: user) }
    let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }
    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:service_double) { instance_double(::Groups::CreateService) }
    let(:data) { { 'path' => 'test' } }

    subject { described_class.new }

    context 'when path is missing' do
      it 'raises an error' do
        expect { subject.load(context, {}) }.to raise_error(described_class::GroupCreationError, 'Path is missing')
      end
    end

    context 'when destination namespace is not a group' do
      it 'raises an error' do
        entity.update!(destination_namespace: user.namespace.path)

        expect { subject.load(context, data) }.to raise_error(described_class::GroupCreationError, 'Destination is not a group')
      end
    end

    context 'when group exists' do
      it 'raises an error' do
        group1 = create(:group)
        group2 = create(:group, parent: group1)
        entity.update!(destination_namespace: group1.full_path)
        data = { 'path' => group2.path }

        expect { subject.load(context, data) }.to raise_error(described_class::GroupCreationError, 'Group exists')
      end
    end

    context 'when there are other group errors' do
      it 'raises an error with those errors' do
        group = ::Group.new
        group.validate
        expected_errors = group.errors.full_messages.to_sentence

        expect(::Groups::CreateService)
          .to receive(:new)
          .with(context.current_user, data)
          .and_return(service_double)

        expect(service_double).to receive(:execute).and_return(group)
        expect(entity).not_to receive(:update!)

        expect { subject.load(context, data) }.to raise_error(described_class::GroupCreationError, expected_errors)
      end
    end

    context 'when user can create group' do
      shared_examples 'calls Group Create Service to create a new group' do
        it 'calls Group Create Service to create a new group' do
          group_double = instance_double(::Group)

          expect(::Groups::CreateService)
            .to receive(:new)
            .with(context.current_user, data)
            .and_return(service_double)

          expect(service_double).to receive(:execute).and_return(group_double)
          expect(group_double).to receive(:errors).and_return([])
          expect(entity).to receive(:update!).with(group: group_double)

          subject.load(context, data)
        end
      end

      context 'when there is no parent group' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :create_group).and_return(true)
        end

        include_examples 'calls Group Create Service to create a new group'
      end

      context 'when there is parent group' do
        let(:parent) { create(:group) }
        let(:data) { { 'parent_id' => parent.id, 'path' => 'test' } }

        before do
          allow(Ability).to receive(:allowed?).with(user, :create_subgroup, parent).and_return(true)
        end

        include_examples 'calls Group Create Service to create a new group'
      end
    end

    context 'when user cannot create group' do
      shared_examples 'does not create new group' do
        it 'does not create new group' do
          expect(::Groups::CreateService).not_to receive(:new)

          expect { subject.load(context, data) }.to raise_error(described_class::GroupCreationError, 'User not allowed to create group')
        end
      end

      context 'when there is no parent group' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :create_group).and_return(false)
        end

        include_examples 'does not create new group'
      end

      context 'when there is parent group' do
        let(:parent) { create(:group) }
        let(:data) { { 'parent_id' => parent.id, 'path' => 'test' } }

        before do
          allow(Ability).to receive(:allowed?).with(user, :create_subgroup, parent).and_return(false)
        end

        include_examples 'does not create new group'
      end
    end
  end
end
