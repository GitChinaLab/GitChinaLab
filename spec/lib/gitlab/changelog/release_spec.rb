# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Changelog::Release do
  describe '#to_markdown' do
    let(:config) { Gitlab::Changelog::Config.new(build_stubbed(:project)) }
    let(:commit) { build_stubbed(:commit) }
    let(:author) { build_stubbed(:user) }
    let(:mr) { build_stubbed(:merge_request) }
    let(:release) do
      described_class
        .new(version: '1.0.0', date: Time.utc(2021, 1, 5), config: config)
    end

    context 'when there are no entries' do
      it 'includes a notice about the lack of entries' do
        expect(release.to_markdown).to eq(<<~OUT)
          ## 1.0.0 (2021-01-05)

          No changes.

        OUT
      end
    end

    context 'when all data is present' do
      it 'includes all data' do
        allow(config).to receive(:contributor?).with(author).and_return(true)

        release.add_entry(
          title: 'Entry title',
          commit: commit,
          category: 'fixed',
          author: author,
          merge_request: mr
        )

        expect(release.to_markdown).to eq(<<~OUT)
          ## 1.0.0 (2021-01-05)

          ### fixed (1 change)

          - [Entry title](#{commit.to_reference(full: true)}) \
          by #{author.to_reference(full: true)} \
          ([merge request](#{mr.to_reference(full: true)}))

        OUT
      end
    end

    context 'when no merge request is present' do
      it "doesn't include a merge request link" do
        allow(config).to receive(:contributor?).with(author).and_return(true)

        release.add_entry(
          title: 'Entry title',
          commit: commit,
          category: 'fixed',
          author: author
        )

        expect(release.to_markdown).to eq(<<~OUT)
          ## 1.0.0 (2021-01-05)

          ### fixed (1 change)

          - [Entry title](#{commit.to_reference(full: true)}) \
          by #{author.to_reference(full: true)}

        OUT
      end
    end

    context 'when the author is not a contributor' do
      it "doesn't include the author" do
        allow(config).to receive(:contributor?).with(author).and_return(false)

        release.add_entry(
          title: 'Entry title',
          commit: commit,
          category: 'fixed',
          author: author
        )

        expect(release.to_markdown).to eq(<<~OUT)
          ## 1.0.0 (2021-01-05)

          ### fixed (1 change)

          - [Entry title](#{commit.to_reference(full: true)})

        OUT
      end
    end

    context 'when the author should always be credited' do
      it 'includes the author' do
        allow(config).to receive(:contributor?).with(author).and_return(false)
        allow(config).to receive(:always_credit_author?).with(author).and_return(true)

        release.add_entry(
          title: 'Entry title',
          commit: commit,
          category: 'fixed',
          author: author
        )

        expect(release.to_markdown).to eq(<<~OUT)
          ## 1.0.0 (2021-01-05)

          ### fixed (1 change)

          - [Entry title](#{commit.to_reference(full: true)}) \
          by #{author.to_reference(full: true)}

        OUT
      end
    end

    context 'when a category has no entries' do
      it "isn't included in the output" do
        config.categories['kittens'] = 'Kittens'
        config.categories['fixed'] = 'Bug fixes'

        release.add_entry(
          title: 'Entry title',
          commit: commit,
          category: 'fixed'
        )

        expect(release.to_markdown).to eq(<<~OUT)
          ## 1.0.0 (2021-01-05)

          ### Bug fixes (1 change)

          - [Entry title](#{commit.to_reference(full: true)})

        OUT
      end
    end
  end

  describe '#header_start_position' do
    it 'returns a regular expression for finding the start of a release section' do
      config = Gitlab::Changelog::Config.new(build_stubbed(:project))
      release = described_class
        .new(version: '1.0.0', date: Time.utc(2021, 1, 5), config: config)

      expect(release.header_start_pattern).to eq(/^##\s*1\.0\.0/)
    end
  end
end
