# frozen_string_literal: true

Gitlab::Database::Partitioning.register_models([
  AuditEvent,
  WebHookLog,
  LooseForeignKeys::DeletedRecord
])

if Gitlab.ee?
  Gitlab::Database::Partitioning.register_models([
    IncidentManagement::PendingEscalations::Alert,
    IncidentManagement::PendingEscalations::Issue
  ])
else
  Gitlab::Database::Partitioning.register_tables([
    {
      table_name: 'incident_management_pending_alert_escalations',
      partitioned_column: :process_at, strategy: :monthly
    },
    {
      table_name: 'incident_management_pending_issue_escalations',
      partitioned_column: :process_at, strategy: :monthly
    }
  ])
end

# The following tables are already defined as models
unless Gitlab.jh?
  Gitlab::Database::Partitioning.register_tables([
    # This should be synchronized with the following model:
    # https://gitlab.com/gitlab-jh/gitlab/-/blob/main-jh/jh/app/models/phone/verification_code.rb
    {
      table_name: 'verification_codes',
      partitioned_column: :created_at, strategy: :monthly
    }
  ])
end

Gitlab::Database::Partitioning.sync_partitions_ignore_db_error
