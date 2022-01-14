# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuables::CrmOrganizationFilter do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let_it_be(:organization1) { create(:organization, group: group) }
  let_it_be(:organization2) { create(:organization, group: group) }
  let_it_be(:contact1) { create(:contact, group: group, organization: organization1) }
  let_it_be(:contact2) { create(:contact, group: group, organization: organization1) }
  let_it_be(:contact3) { create(:contact, group: group, organization: organization2) }

  let_it_be(:contact1_issue) { create(:issue, project: project) }
  let_it_be(:contact2_issue) { create(:issue, project: project) }
  let_it_be(:contact3_issue) { create(:issue, project: project) }
  let_it_be(:issues) { Issue.where(id: [contact1_issue.id, contact2_issue.id, contact3_issue.id]) }

  before_all do
    create(:issue_customer_relations_contact, issue: contact1_issue, contact: contact1)
    create(:issue_customer_relations_contact, issue: contact2_issue, contact: contact2)
    create(:issue_customer_relations_contact, issue: contact3_issue, contact: contact3)
  end

  describe 'when an organization has issues' do
    it 'returns all organization1 issues' do
      params = { crm_organization_id: organization1.id }

      expect(described_class.new(params: params).filter(issues)).to contain_exactly(contact1_issue, contact2_issue)
    end

    it 'returns all organization2 issues' do
      params = { crm_organization_id: organization2.id }

      expect(described_class.new(params: params).filter(issues)).to contain_exactly(contact3_issue)
    end
  end

  describe 'when an organization has no issues' do
    it 'returns no issues' do
      organization3 = create(:organization, group: group)
      params = { crm_organization_id: organization3.id }

      expect(described_class.new(params: params).filter(issues)).to be_empty
    end
  end
end
