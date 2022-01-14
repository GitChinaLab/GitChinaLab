# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::BuildService do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:user) { developer }

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)
  end

  def build_issue(issue_params = {})
    described_class.new(project: project, current_user: user, params: issue_params).execute
  end

  context 'for a single discussion' do
    describe '#execute' do
      let(:merge_request) { create(:merge_request, title: "Hello world", source_project: project) }
      let(:discussion) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, note: "Almost done").to_discussion }

      subject { build_issue(merge_request_to_resolve_discussions_of: merge_request.iid, discussion_to_resolve: discussion.id) }

      it 'references the noteable title in the issue title' do
        expect(subject.title).to include('Hello world')
      end

      it 'adds the note content to the description' do
        expect(subject.description).to include('Almost done')
      end
    end
  end

  context 'for discussions in a merge request' do
    let(:merge_request) { create(:merge_request_with_diff_notes, source_project: project) }

    describe '#items_for_discussions' do
      it 'has an item for each discussion' do
        create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.source_project, line_number: 13)
        service = described_class.new(project: project, current_user: user, params: { merge_request_to_resolve_discussions_of: merge_request.iid })

        service.execute

        expect(service.items_for_discussions.size).to eq(2)
      end
    end

    describe '#item_for_discussion' do
      let(:service) { described_class.new(project: project, current_user: user, params: { merge_request_to_resolve_discussions_of: merge_request.iid }) }

      it 'mentions the author of the note' do
        discussion = create(:diff_note_on_merge_request, author: create(:user, username: 'author')).to_discussion
        expect(service.item_for_discussion(discussion)).to include('@author')
      end

      it 'wraps the note in a blockquote' do
        note_text = "This is a string\n"\
                    ">>>\n"\
                    "with a blockquote\n"\
                    "> That has a quote\n"\
                    ">>>\n"
        note_result = "    > This is a string\n"\
                      "    > \n"\
                      "    > > with a blockquote\n"\
                      "    > > > That has a quote\n"\
                      "    > \n"
        discussion = create(:diff_note_on_merge_request, note: note_text).to_discussion
        expect(service.item_for_discussion(discussion)).to include(note_result)
      end
    end

    describe '#execute' do
      let(:base_params) { { merge_request_to_resolve_discussions_of: merge_request.iid } }

      context 'without additional params' do
        subject { build_issue(base_params) }

        it 'has the merge request reference in the title' do
          expect(subject.title).to include(merge_request.title)
        end

        it 'has the reference of the merge request in the description' do
          expect(subject.description).to include(merge_request.to_reference)
        end
      end

      it 'uses provided title if title param given' do
        issue = build_issue(base_params.merge(title: 'What an issue'))

        expect(issue.title).to eq('What an issue')
      end

      it 'uses provided description if description param given' do
        issue = build_issue(base_params.merge(description: 'Fix at your earliest convenience'))

        expect(issue.description).to eq('Fix at your earliest convenience')
      end

      describe 'with multiple discussions' do
        let!(:diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.target_project, line_number: 15) }

        it 'mentions all the authors in the description' do
          authors = merge_request.resolvable_discussions.map(&:author)

          expect(build_issue(base_params).description).to include(*authors.map(&:to_reference))
        end

        it 'has a link for each unresolved discussion in the description' do
          notes = merge_request.resolvable_discussions.map(&:first_note)
          links = notes.map { |note| Gitlab::UrlBuilder.build(note) }

          expect(build_issue(base_params).description).to include(*links)
        end

        it 'mentions additional notes' do
          create_list(:diff_note_on_merge_request, 2, noteable: merge_request, project: merge_request.target_project, in_reply_to: diff_note)

          expect(build_issue(base_params).description).to include('(+2 comments)')
        end
      end
    end
  end

  context 'For a merge request without discussions' do
    let(:merge_request) { create(:merge_request, source_project: project) }

    describe '#execute' do
      it 'mentions the merge request in the description' do
        issue = build_issue(merge_request_to_resolve_discussions_of: merge_request.iid)

        expect(issue.description).to include("Review the conversation in #{merge_request.to_reference}")
      end
    end
  end

  describe '#execute' do
    describe 'setting milestone' do
      context 'when developer' do
        it 'builds a new issues with given params' do
          milestone = create(:milestone, project: project)
          issue = build_issue(milestone_id: milestone.id)

          expect(issue.milestone).to eq(milestone)
        end

        it 'sets milestone to nil if it is not available for the project' do
          milestone = create(:milestone, project: create(:project))
          issue = build_issue(milestone_id: milestone.id)

          expect(issue.milestone).to be_nil
        end
      end

      context 'when guest' do
        let(:user) { guest }

        it 'cannot set milestone' do
          milestone = create(:milestone, project: project)
          issue = build_issue(milestone_id: milestone.id)

          expect(issue.milestone).to be_nil
        end
      end
    end

    describe 'setting issue type' do
      context 'with a corresponding WorkItem::Type' do
        let_it_be(:type_issue_id) { WorkItem::Type.default_issue_type.id }
        let_it_be(:type_incident_id) { WorkItem::Type.default_by_type(:incident).id }

        where(:issue_type, :current_user, :work_item_type_id, :resulting_issue_type) do
          nil           | ref(:guest)    | ref(:type_issue_id)       | 'issue'
          'issue'       | ref(:guest)    | ref(:type_issue_id)       | 'issue'
          'incident'    | ref(:guest)    | ref(:type_issue_id)       | 'issue'
          'incident'    | ref(:reporter) | ref(:type_incident_id)    | 'incident'
          # update once support for test_case is enabled
          'test_case'   | ref(:guest)    | ref(:type_issue_id)       | 'issue'
          # update once support for requirement is enabled
          'requirement' | ref(:guest)    | ref(:type_issue_id)       | 'issue'
          'invalid'     | ref(:guest)    | ref(:type_issue_id)       | 'issue'
          # ensure that we don't set a value which has a permission check but is an invalid issue type
          'project'     | ref(:guest)    | ref(:type_issue_id)       | 'issue'
        end

        with_them do
          let(:user) { current_user }

          it 'builds an issue' do
            issue = build_issue(issue_type: issue_type)

            expect(issue.issue_type).to eq(resulting_issue_type)
            expect(issue.work_item_type_id).to eq(work_item_type_id)
          end
        end
      end
    end
  end
end
