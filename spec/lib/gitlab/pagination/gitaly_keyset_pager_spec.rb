# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::GitalyKeysetPager do
  let(:pager) { described_class.new(request_context, project) }

  let_it_be(:project) { create(:project, :repository) }

  let(:request_context) { double("request context") }
  let(:finder) { double("branch finder") }
  let(:custom_port) { 8080 }
  let(:incoming_api_projects_url) { "#{Gitlab.config.gitlab.url}:#{custom_port}/api/v4/projects" }

  before do
    stub_config_setting(port: custom_port)
  end

  describe '.paginate' do
    let(:base_query) { { per_page: 2 } }
    let(:query) { base_query }

    before do
      allow(request_context).to receive(:params).and_return(query)
      allow(request_context).to receive(:header)
    end

    shared_examples_for 'offset pagination' do
      let(:paginated_array) { double 'paginated array' }
      let(:branches) { [] }

      it 'uses offset pagination' do
        expect(finder).to receive(:execute).and_return(branches)
        expect(Kaminari).to receive(:paginate_array).with(branches).and_return(paginated_array)
        expect_next_instance_of(Gitlab::Pagination::OffsetPagination) do |offset_pagination|
          expect(offset_pagination).to receive(:paginate).with(paginated_array)
        end

        pager.paginate(finder)
      end
    end

    context 'with branch_list_keyset_pagination feature off' do
      before do
        stub_feature_flags(branch_list_keyset_pagination: false)
      end

      context 'without keyset pagination option' do
        it_behaves_like 'offset pagination'
      end

      context 'with keyset pagination option' do
        let(:query) { base_query.merge(pagination: 'keyset') }

        it_behaves_like 'offset pagination'
      end
    end

    context 'with branch_list_keyset_pagination feature on' do
      let(:fake_request) { double(url: "#{incoming_api_projects_url}?#{query.to_query}") }
      let(:branch1) { double 'branch', name: 'branch1' }
      let(:branch2) { double 'branch', name: 'branch2' }
      let(:branch3) { double 'branch', name: 'branch3' }

      before do
        stub_feature_flags(branch_list_keyset_pagination: project)
      end

      context 'without keyset pagination option' do
        context 'when first page is requested' do
          let(:branches) { [branch1, branch2, branch3] }

          it 'keyset pagination is used with offset headers' do
            allow(request_context).to receive(:request).and_return(fake_request)
            allow(project.repository).to receive(:branch_count).and_return(branches.size)

            expect(finder).to receive(:execute).and_return(branches)
            expect(request_context).to receive(:header).with('X-Per-Page', '2')
            expect(request_context).to receive(:header).with('X-Page', '1')
            expect(request_context).to receive(:header).with('X-Next-Page', '2')
            expect(request_context).to receive(:header).with('X-Prev-Page', '')
            expect(request_context).to receive(:header).with('Link', kind_of(String))
            expect(request_context).to receive(:header).with('X-Total', '3')
            expect(request_context).to receive(:header).with('X-Total-Pages', '2')

            pager.paginate(finder)
          end
        end

        context 'when second page is requested' do
          let(:base_query) { { per_page: 2, page: 2 } }

          it_behaves_like 'offset pagination'
        end
      end

      context 'with keyset pagination option' do
        let(:query) { base_query.merge(pagination: 'keyset') }

        before do
          allow(request_context).to receive(:request).and_return(fake_request)
          allow(finder).to receive(:is_a?).with(BranchesFinder) { true }
          expect(finder).to receive(:execute).with(gitaly_pagination: true).and_return(branches)
        end

        context 'when next page could be available' do
          let(:branches) { [branch1, branch2] }

          let(:expected_next_page_link) { %Q(<#{incoming_api_projects_url}?#{query.merge(page_token: branch2.name).to_query}>; rel="next") }

          it 'uses keyset pagination and adds link headers' do
            expect(request_context).to receive(:header).with('Link', expected_next_page_link)

            pager.paginate(finder)
          end
        end

        context 'when the current page is the last page' do
          let(:branches) { [branch1] }

          it 'uses keyset pagination without link headers' do
            expect(request_context).not_to receive(:header).with('Link', anything)

            pager.paginate(finder)
          end
        end
      end
    end
  end
end
