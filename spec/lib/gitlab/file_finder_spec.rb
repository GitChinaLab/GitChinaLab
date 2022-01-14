# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FileFinder do
  describe '#find' do
    let(:project) { create(:project, :public, :repository) }

    subject { described_class.new(project, project.default_branch) }

    it_behaves_like 'file finder' do
      let(:expected_file_by_path) { 'files/images/wm.svg' }
      let(:expected_file_by_content) { 'CHANGELOG' }
    end

    context 'with inclusive filters' do
      it 'filters by filename' do
        results = subject.find('files filename:wm.svg')

        expect(results.count).to eq(1)
      end

      it 'filters by path' do
        results = subject.find('white path:images')

        expect(results.count).to eq(1)
      end

      it 'filters by extension' do
        results = subject.find('files extension:md')

        expect(results.count).to eq(4)
      end
    end

    context 'with exclusive filters' do
      it 'filters by filename' do
        results = subject.find('files -filename:wm.svg')

        expect(results.count).to eq(26)
      end

      it 'filters by path' do
        results = subject.find('white -path:images')

        expect(results.count).to eq(4)
      end

      it 'filters by extension' do
        results = subject.find('files -extension:md')

        expect(results.count).to eq(23)
      end
    end

    context 'with white space in the path' do
      it 'filters by path correctly' do
        results = subject.find('directory path:"with space/README.md"')

        expect(results.count).to eq(1)
      end
    end

    it 'does not cause N+1 query' do
      expect(Gitlab::GitalyClient).to receive(:call).at_most(10).times.and_call_original

      subject.find(': filename:wm.svg')
    end
  end
end
