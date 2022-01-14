# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTags::UpdateService do
  let(:protected_tag) { create(:protected_tag) }
  let(:project) { protected_tag.project }
  let(:user) { project.owner }
  let(:params) { { name: new_name } }

  describe '#execute' do
    let(:new_name) { 'new protected tag name' }
    let(:result) { service.execute(protected_tag) }

    subject(:service) { described_class.new(project, user, params) }

    it 'updates a protected tag' do
      expect(result.reload.name).to eq(params[:name])
    end

    context 'when name has escaped HTML' do
      let(:new_name) { 'tag-&gt;test' }

      it 'updates protected tag name with unescaped HTML' do
        expect(result.reload.name).to eq('tag->test')
      end

      context 'and name contains HTML tags' do
        let(:new_name) { '&lt;b&gt;tag&lt;/b&gt;' }

        it 'updates protected tag name with sanitized name' do
          expect(result.reload.name).to eq('tag')
        end

        context 'and contains unsafe HTML' do
          let(:new_name) { '&lt;script&gt;alert(&#39;foo&#39;);&lt;/script&gt;' }

          it 'does not update the protected tag' do
            expect(result.reload.name).to eq(protected_tag.name)
          end
        end
      end
    end

    context 'when name contains unescaped HTML tags' do
      let(:new_name) { '<b>tag</b>' }

      it 'updates protected tag name with sanitized name' do
        expect(result.reload.name).to eq('tag')
      end
    end

    context 'without admin_project permissions' do
      let(:user) { create(:user) }

      it "raises error" do
        expect { service.execute(protected_tag) }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
