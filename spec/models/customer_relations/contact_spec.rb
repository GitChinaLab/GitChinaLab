# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Contact, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to have_many(:issue_contacts) }
    it { is_expected.to have_many(:issues) }
  end

  describe 'validations' do
    subject { build(:contact) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }

    it { is_expected.to validate_length_of(:phone).is_at_most(32) }
    it { is_expected.to validate_length_of(:first_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:last_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:email).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }

    it_behaves_like 'an object with RFC3696 compliant email-formatted attributes', :email
  end

  describe '#before_validation' do
    it 'strips leading and trailing whitespace' do
      contact = described_class.new(first_name: '  First  ', last_name: ' Last  ', phone: '  123456 ')
      contact.valid?

      expect(contact.first_name).to eq('First')
      expect(contact.last_name).to eq('Last')
      expect(contact.phone).to eq('123456')
    end
  end

  describe '#self.find_ids_by_emails' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_contacts) { create_list(:contact, 2, group: group) }
    let_it_be(:other_contacts) { create_list(:contact, 2) }

    it 'returns ids of contacts from group' do
      contact_ids = described_class.find_ids_by_emails(group.id, group_contacts.pluck(:email))

      expect(contact_ids).to match_array(group_contacts.pluck(:id))
    end

    it 'does not return ids of contacts from other groups' do
      contact_ids = described_class.find_ids_by_emails(group.id, other_contacts.pluck(:email))

      expect(contact_ids).to be_empty
    end

    it 'raises ArgumentError when called with too many emails' do
      too_many_emails = described_class::MAX_PLUCK + 1
      expect { described_class.find_ids_by_emails(group.id, Array(0..too_many_emails)) }.to raise_error(ArgumentError)
    end
  end
end
