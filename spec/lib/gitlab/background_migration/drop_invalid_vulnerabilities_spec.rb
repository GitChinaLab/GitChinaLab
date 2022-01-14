# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DropInvalidVulnerabilities, schema: 20181228175414 do
  let_it_be(:background_migration_jobs) { table(:background_migration_jobs) }
  let_it_be(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let_it_be(:users) { table(:users) }
  let_it_be(:user) { create_user! }
  let_it_be(:project) { table(:projects).create!(id: 123, namespace_id: namespace.id) }

  let_it_be(:scanners) { table(:vulnerability_scanners) }
  let_it_be(:scanner) { scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }
  let_it_be(:different_scanner) { scanners.create!(project_id: project.id, external_id: 'test 2', name: 'test scanner 2') }

  let_it_be(:vulnerabilities) { table(:vulnerabilities) }
  let_it_be(:vulnerability_with_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let_it_be(:vulnerability_without_finding) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let_it_be(:vulnerability_identifiers) { table(:vulnerability_identifiers) }
  let_it_be(:primary_identifier) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: 'uuid-v5',
      external_id: 'uuid-v5',
      fingerprint: '7e394d1b1eb461a7406d7b1e08f057a1cf11287a',
      name: 'Identifier for UUIDv5')
  end

  let_it_be(:vulnerabilities_findings) { table(:vulnerability_occurrences) }
  let_it_be(:finding) do
    create_finding!(
      vulnerability_id: vulnerability_with_finding.id,
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: primary_identifier.id
    )
  end

  let(:succeeded_status) { 1 }
  let(:pending_status) { 0 }

  it 'drops Vulnerabilities without any Findings' do
    expect(vulnerabilities.pluck(:id)).to eq([vulnerability_with_finding.id, vulnerability_without_finding.id])

    expect { subject.perform(vulnerability_with_finding.id, vulnerability_without_finding.id) }.to change(vulnerabilities, :count).by(-1)

    expect(vulnerabilities.pluck(:id)).to eq([vulnerability_with_finding.id])
  end

  it 'marks jobs as done' do
    background_migration_jobs.create!(
      class_name: 'DropInvalidVulnerabilities',
      arguments: [vulnerability_with_finding.id, vulnerability_with_finding.id]
    )

    background_migration_jobs.create!(
      class_name: 'DropInvalidVulnerabilities',
      arguments: [vulnerability_without_finding.id, vulnerability_without_finding.id]
    )

    subject.perform(vulnerability_with_finding.id, vulnerability_with_finding.id)

    expect(background_migration_jobs.first.status).to eq(succeeded_status)
    expect(background_migration_jobs.second.status).to eq(pending_status)
  end

  private

  def create_vulnerability!(project_id:, author_id:, title: 'test', severity: 7, confidence: 7, report_type: 0)
    vulnerabilities.create!(
      project_id: project_id,
      author_id: author_id,
      title: title,
      severity: severity,
      confidence: confidence,
      report_type: report_type
    )
  end

  # rubocop:disable Metrics/ParameterLists
  def create_finding!(
    vulnerability_id:, project_id:, scanner_id:, primary_identifier_id:,
                      name: "test", severity: 7, confidence: 7, report_type: 0,
                      project_fingerprint: '123qweasdzxc', location_fingerprint: 'test',
                      metadata_version: 'test', raw_metadata: 'test', uuid: 'test')
    vulnerabilities_findings.create!(
      vulnerability_id: vulnerability_id,
      project_id: project_id,
      name: name,
      severity: severity,
      confidence: confidence,
      report_type: report_type,
      project_fingerprint: project_fingerprint,
      scanner_id: scanner_id,
      primary_identifier_id: primary_identifier_id,
      location_fingerprint: location_fingerprint,
      metadata_version: metadata_version,
      raw_metadata: raw_metadata,
      uuid: uuid
    )
  end
  # rubocop:enable Metrics/ParameterLists

  def create_user!(name: "Example User", email: "user@example.com", user_type: nil)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      user_type: user_type,
      confirmed_at: Time.current
    )
  end
end
