# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobPresenter do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  let(:repository) { project.repository }
  let(:blob) { repository.blob_at('HEAD', 'files/ruby/regex.rb') }

  subject(:presenter) { described_class.new(blob, current_user: user) }

  describe '#web_url' do
    it { expect(presenter.web_url).to eq("http://localhost/#{project.full_path}/-/blob/#{blob.commit_id}/#{blob.path}") }
  end

  describe '#web_path' do
    it { expect(presenter.web_path).to eq("/#{project.full_path}/-/blob/#{blob.commit_id}/#{blob.path}") }
  end

  describe '#edit_blob_path' do
    it { expect(presenter.edit_blob_path).to eq("/#{project.full_path}/-/edit/#{blob.commit_id}/#{blob.path}") }
  end

  describe '#raw_path' do
    it { expect(presenter.raw_path).to eq("/#{project.full_path}/-/raw/#{blob.commit_id}/#{blob.path}") }
  end

  describe '#replace_path' do
    it { expect(presenter.replace_path).to eq("/#{project.full_path}/-/create/#{blob.commit_id}/#{blob.path}") }
  end

  describe '#can_current_user_push_to_branch' do
    let(:branch_exists) { true }

    before do
      allow(project.repository).to receive(:branch_exists?).with(blob.commit_id).and_return(branch_exists)
    end

    it { expect(presenter.can_current_user_push_to_branch?).to eq(true) }

    context 'current_user is nil' do
      let(:user) { nil }

      it { expect(presenter.can_current_user_push_to_branch?).to eq(false) }
    end

    context 'branch does not exist' do
      let(:branch_exists) { false }

      it { expect(presenter.can_current_user_push_to_branch?).to eq(false) }
    end
  end

  describe '#pipeline_editor_path' do
    context 'when blob is .gitlab-ci.yml' do
      before do
        project.repository.create_file(user, '.gitlab-ci.yml', '',
        message: 'Add a ci file',
        branch_name: 'main')
      end

      let(:blob) { repository.blob_at('main', '.gitlab-ci.yml') }

      it { expect(presenter.pipeline_editor_path).to eq("/#{project.full_path}/-/ci/editor?branch_name=#{blob.commit_id}") }
    end
  end

  describe '#code_owners' do
    it { expect(presenter.code_owners).to match_array([]) }
  end

  describe '#ide_edit_path' do
    it { expect(presenter.ide_edit_path).to eq("/-/ide/project/#{project.full_path}/edit/HEAD/-/files/ruby/regex.rb") }
  end

  describe '#fork_and_edit_path' do
    it 'generates expected URI + query' do
      uri = URI.parse(presenter.fork_and_edit_path)
      query = Rack::Utils.parse_query(uri.query)

      expect(uri.path).to eq("/#{project.full_path}/-/forks")
      expect(query).to include('continue[to]' => presenter.edit_blob_path, 'namespace_key' => user.namespace_id.to_s)
    end

    context 'current_user is nil' do
      let(:user) { nil }

      it { expect(presenter.fork_and_edit_path).to be_nil }
    end
  end

  describe '#ide_fork_and_edit_path' do
    it 'generates expected URI + query' do
      uri = URI.parse(presenter.ide_fork_and_edit_path)
      query = Rack::Utils.parse_query(uri.query)

      expect(uri.path).to eq("/#{project.full_path}/-/forks")
      expect(query).to include('continue[to]' => presenter.ide_edit_path, 'namespace_key' => user.namespace_id.to_s)
    end

    context 'current_user is nil' do
      let(:user) { nil }

      it { expect(presenter.ide_fork_and_edit_path).to be_nil }
    end
  end

  context 'given a Gitlab::Graphql::Representation::TreeEntry' do
    let(:blob) { Gitlab::Graphql::Representation::TreeEntry.new(super(), repository) }

    describe '#web_url' do
      it { expect(presenter.web_url).to eq("http://localhost/#{project.full_path}/-/blob/#{blob.commit_id}/#{blob.path}") }
    end

    describe '#web_path' do
      it { expect(presenter.web_path).to eq("/#{project.full_path}/-/blob/#{blob.commit_id}/#{blob.path}") }
    end
  end

  describe '#highlight' do
    let(:git_blob) { blob.__getobj__ }

    it 'returns highlighted content' do
      expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: nil, language: nil)

      presenter.highlight
    end

    it 'returns plain content when :plain is true' do
      expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: true, language: nil)

      presenter.highlight(plain: true)
    end

    context '"to" param is present' do
      before do
        allow(git_blob)
          .to receive(:data)
          .and_return("line one\nline two\nline 3")
      end

      it 'returns limited highlighted content' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', "line one\n", plain: nil, language: nil)

        presenter.highlight(to: 1)
      end
    end

    context 'gitlab-language contains a match' do
      before do
        allow(blob).to receive(:language_from_gitattributes).and_return('ruby')
      end

      it 'passes language to inner call' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: nil, language: 'ruby')

        presenter.highlight
      end
    end

    context 'when blob is ipynb' do
      let(:blob) { repository.blob_at('f6b7a707', 'files/ipython/markdown-table.ipynb') }
      let(:git_blob) { blob.__getobj__ }

      before do
        allow(Gitlab::Diff::CustomDiff).to receive(:transformed_for_diff?).and_return(true)
      end

      it 'uses md as the transformed language' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ipython/markdown-table.ipynb', anything, plain: nil, language: 'md')

        presenter.highlight
      end

      it 'transforms the blob' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ipython/markdown-table.ipynb', include("%%"), plain: nil, language: 'md')

        presenter.highlight
      end
    end

    context 'when blob is other file type' do
      let(:git_blob) { blob.__getobj__ }

      before do
        allow(git_blob)
          .to receive(:data)
                .and_return("line one\nline two\nline 3")

        allow(blob).to receive(:language_from_gitattributes).and_return('ruby')
      end

      it 'does not transform the file' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: nil, language: 'ruby')

        presenter.highlight
      end
    end
  end

  describe '#raw_plain_data' do
    let(:blob) { repository.blob_at('HEAD', file) }

    context 'when blob is text' do
      let(:file) { 'files/ruby/popen.rb' }

      it 'does not include html in the content' do
        expect(presenter.raw_plain_data.include?('</span>')).to be_falsey
      end
    end
  end

  describe '#plain_data' do
    let(:blob) { repository.blob_at('HEAD', file) }

    context 'when blob is binary' do
      let(:file) { 'files/images/logo-black.png' }

      it 'returns nil' do
        expect(presenter.plain_data).to be_nil
      end
    end

    context 'when blob is markup' do
      let(:file) { 'README.md' }

      it 'returns plain content' do
        expect(presenter.plain_data).to include('<span id="LC1" class="line" lang="markdown">')
      end
    end

    context 'when blob has syntax' do
      let(:file) { 'files/ruby/regex.rb' }

      it 'returns highlighted syntax content' do
        expect(presenter.plain_data)
          .to include '<span id="LC1" class="line" lang="ruby"><span class="k">module</span> <span class="nn">Gitlab</span>'
      end
    end

    context 'when blob has plain data' do
      let(:file) { 'LICENSE' }

      it 'returns plain text highlighted content' do
        expect(presenter.plain_data).to include('<span id="LC1" class="line" lang="plaintext">The MIT License (MIT)</span>')
      end
    end
  end
end
