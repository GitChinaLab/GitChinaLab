# frozen_string_literal: true

RSpec.shared_examples 'date sidebar widget' do
  context 'editing due date' do
    let(:due_date_value) { find('[data-testid="sidebar-due-date"] [data-testid="sidebar-date-value"]') }

    around do |example|
      freeze_time { example.run }
    end

    it 'displays "None" when there is no due date' do
      expect(due_date_value.text).to have_content 'None'
    end

    it 'updates due date' do
      page.within('[data-testid="sidebar-due-date"]') do
        today = Date.today.day

        click_button 'Edit'

        click_button today.to_s

        wait_for_requests

        expect(page).to have_content(today.to_s(:medium))
        expect(due_date_value.text).to have_content Time.current.strftime('%b %-d, %Y')
      end
    end
  end
end
