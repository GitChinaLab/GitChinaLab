# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicenseTemplateFinder do
  RSpec.shared_examples 'filters by popular category' do
    context 'popular: true' do
      let(:params) { { popular: true } }

      it 'only returns popular licenses' do
        expect(categories).to contain_exactly(:Popular)
        expect(categorised_licenses[:Popular]).to be_present
      end
    end

    context 'popular: false' do
      let(:params) { { popular: false } }

      it 'only returns unpopular licenses' do
        expect(categories).to contain_exactly(:Other)
        expect(categorised_licenses[:Other]).to be_present
      end
    end
  end

  describe '#execute' do
    subject(:result) { described_class.new(nil, params).execute }

    let(:categories) { categorised_licenses.keys }
    let(:categorised_licenses) { result.group_by(&:category) }

    it_behaves_like 'filters by popular category'

    context 'popular: nil' do
      let(:params) { { popular: nil } }

      it 'returns all licenses known by the Licensee gem' do
        from_licensee = Licensee::License.all.map { |l| l.key }

        expect(result.map(&:key)).to match_array(from_licensee)
      end

      it 'correctly copies all attributes' do
        licensee = Licensee::License.all.first
        found = result.find { |r| r.key == licensee.key }

        aggregate_failures do
          %i[key name content nickname url meta featured?].each do |k|
            expect(found.public_send(k)).to eq(licensee.public_send(k))
          end
        end
      end
    end
  end

  describe '#template_names' do
    let(:params) { {} }

    subject(:template_names) { described_class.new(nil, params).template_names }

    let(:categories) { categorised_licenses.keys }
    let(:categorised_licenses) { template_names }

    it_behaves_like 'filters by popular category'

    context 'popular: nil' do
      let(:params) { { popular: nil } }

      it 'returns all licenses known by the Licensee gem' do
        from_licensee = Licensee::License.all.map { |l| l.key }

        expect(template_names.values.flatten.map { |x| x[:key] }).to match_array(from_licensee)
      end
    end

    context 'template names hash keys' do
      it 'has all the expected keys' do
        expect(template_names.values.flatten.first.keys).to match_array(%i(id key name project_id))
      end
    end
  end
end
