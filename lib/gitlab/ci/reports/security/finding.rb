# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Finding
          include ::VulnerabilityFindingHelpers

          attr_reader :compare_key
          attr_reader :confidence
          attr_reader :identifiers
          attr_reader :flags
          attr_reader :links
          attr_reader :location
          attr_reader :metadata_version
          attr_reader :name
          attr_reader :old_location
          attr_reader :project_fingerprint
          attr_reader :report_type
          attr_reader :scanner
          attr_reader :scan
          attr_reader :severity
          attr_accessor :uuid
          attr_accessor :overridden_uuid
          attr_reader :remediations
          attr_reader :details
          attr_reader :signatures
          attr_reader :project_id
          attr_reader :original_data

          delegate :file_path, :start_line, :end_line, to: :location

          alias_method :cve, :compare_key

          def initialize(compare_key:, identifiers:, flags: [], links: [], remediations: [], location:, metadata_version:, name:, original_data:, report_type:, scanner:, scan:, uuid:, confidence: nil, severity: nil, details: {}, signatures: [], project_id: nil, vulnerability_finding_signatures_enabled: false) # rubocop:disable Metrics/ParameterLists
            @compare_key = compare_key
            @confidence = confidence
            @identifiers = identifiers
            @flags = flags
            @links = links
            @location = location
            @metadata_version = metadata_version
            @name = name
            @original_data = original_data
            @report_type = report_type
            @scanner = scanner
            @scan = scan
            @severity = severity
            @uuid = uuid
            @remediations = remediations
            @details = details
            @signatures = signatures
            @project_id = project_id
            @vulnerability_finding_signatures_enabled = vulnerability_finding_signatures_enabled

            @project_fingerprint = generate_project_fingerprint
          end

          def to_hash
            %i[
              compare_key
              confidence
              identifiers
              flags
              links
              location
              metadata_version
              name
              project_fingerprint
              raw_metadata
              report_type
              scanner
              scan
              severity
              uuid
              details
              signatures
              description
              message
              cve
              solution
            ].each_with_object({}) do |key, hash|
              hash[key] = public_send(key) # rubocop:disable GitlabSecurity/PublicSend
            end
          end

          def primary_identifier
            identifiers.first
          end

          def update_location(new_location)
            @old_location = location
            @location = new_location
          end

          def unsafe?(severity_levels, report_types)
            severity.to_s.in?(severity_levels) && (report_types.blank? || report_type.to_s.in?(report_types) )
          end

          def eql?(other)
            return false unless report_type == other.report_type && primary_identifier_fingerprint == other.primary_identifier_fingerprint

            if @vulnerability_finding_signatures_enabled
              matches_signatures(other.signatures, other.uuid)
            else
              location.fingerprint == other.location.fingerprint
            end
          end

          def hash
            if @vulnerability_finding_signatures_enabled && !signatures.empty?
              highest_signature = signatures.max_by(&:priority)
              report_type.hash ^ highest_signature.signature_hex.hash ^ primary_identifier_fingerprint.hash
            else
              report_type.hash ^ location.fingerprint.hash ^ primary_identifier_fingerprint.hash
            end
          end

          def valid?
            scanner.present? && primary_identifier.present? && location.present? && uuid.present?
          end

          def keys
            @keys ||= identifiers.reject(&:type_identifier?).map do |identifier|
              FindingKey.new(location_fingerprint: location&.fingerprint, identifier_fingerprint: identifier.fingerprint)
            end
          end

          def primary_identifier_fingerprint
            primary_identifier&.fingerprint
          end

          def <=>(other)
            if severity == other.severity
              compare_key <=> other.compare_key
            else
              ::Enums::Vulnerability.severity_levels[other.severity] <=>
                ::Enums::Vulnerability.severity_levels[severity]
            end
          end

          def scanner_order_to(other)
            return 1 unless scanner
            return -1 unless other&.scanner

            scanner <=> other.scanner
          end

          def has_signatures?
            signatures.present?
          end

          def raw_metadata
            @raw_metadata ||= original_data.to_json
          end

          def description
            original_data['description']
          end

          def message
            original_data['message']
          end

          def solution
            original_data['solution']
          end

          def location_data
            original_data['location']
          end

          private

          def generate_project_fingerprint
            Digest::SHA1.hexdigest(compare_key)
          end
        end
      end
    end
  end
end
