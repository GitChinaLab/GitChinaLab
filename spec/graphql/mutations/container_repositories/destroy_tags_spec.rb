# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ContainerRepositories::DestroyTags do
  include_context 'container repository delete tags service shared context'
  using RSpec::Parameterized::TableSyntax

  let(:id) { repository.to_global_id.to_s }

  specify { expect(described_class).to require_graphql_authorizations(:destroy_container_image) }

  describe '#resolve' do
    let(:tags) { %w[A C D E] }

    subject do
      described_class.new(object: nil, context: { current_user: user }, field: nil)
                     .resolve(id: id, tag_names: tags)
    end

    shared_examples 'destroying container repository tags' do
      before do
        stub_delete_reference_requests(tags)
        expect_delete_tag_by_names(tags)
        allow_next_instance_of(ContainerRegistry::Client) do |client|
          allow(client).to receive(:supports_tag_delete?).and_return(true)
        end
      end

      it 'destroys the container repository tags' do
        expect(Projects::ContainerRepository::DeleteTagsService)
          .to receive(:new).and_call_original

        expect(subject).to eq(errors: [], deleted_tag_names: tags)
      end

      it 'creates a package event' do
        expect(::Packages::CreateEventService)
          .to receive(:new).with(nil, user, event_name: :delete_tag_bulk, scope: :tag).and_call_original
        expect { subject }.to change { ::Packages::Event.count }.by(1)
      end
    end

    shared_examples 'denying access to container respository' do
      it 'raises an error' do
        expect(::Projects::ContainerRepository::DeleteTagsService).not_to receive(:new)

        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with valid id' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'destroying container repository tags'
        :developer  | 'destroying container repository tags'
        :reporter   | 'denying access to container respository'
        :guest      | 'denying access to container respository'
        :anonymous  | 'denying access to container respository'
      end

      with_them do
        before do
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'with invalid id' do
      let(:id) { 'gid://gitlab/ContainerRepository/5555' }

      it_behaves_like 'denying access to container respository'
    end

    context 'with service error' do
      before do
        project.add_maintainer(user)
        allow_next_instance_of(Projects::ContainerRepository::DeleteTagsService) do |service|
          allow(service).to receive(:execute).and_return(message: 'could not delete tags', status: :error)
        end
      end

      it { is_expected.to eq(errors: ['could not delete tags'], deleted_tag_names: []) }

      it 'does not create a package event' do
        expect(::Packages::CreateEventService).not_to receive(:new)
        expect { subject }.not_to change { ::Packages::Event.count }
      end
    end
  end
end
