# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::IssueStageEnd do
  it_behaves_like 'value stream analytics event'

  it_behaves_like 'LEFT JOIN-able value stream analytics event' do
    let_it_be(:record_with_data) { create(:issue).tap { |i| i.metrics.update!(first_added_to_board_at: Time.current) } }
    let_it_be(:record_without_data) { create(:issue) }
  end
end
