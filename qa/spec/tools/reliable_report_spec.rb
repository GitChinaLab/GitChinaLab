# frozen_string_literal: true

describe QA::Tools::ReliableReport do
  include QA::Support::Helpers::StubEnv

  subject(:run) { described_class.run(range: range, report_in_issue_and_slack: create_issue) }

  let(:gitlab_response) { instance_double("RestClient::Response", code: 200, body: { web_url: issue_url }.to_json) }
  let(:slack_notifier) { instance_double("Slack::Notifier", post: nil) }
  let(:influx_client) { instance_double("InfluxDB2::Client", create_query_api: query_api) }
  let(:query_api) { instance_double("InfluxDB2::QueryApi") }

  let(:slack_channel) { "#quality-reports" }
  let(:range) { 14 }
  let(:issue_url) { "https://gitlab.com/issue/1" }

  let(:runs) do
    values = { "name" => "stable spec", "status" => "passed", "file_path" => "some/spec.rb", "stage" => "manage" }
    {
      0 => instance_double(
        "InfluxDB2::FluxTable",
        records: [
          instance_double("InfluxDB2::FluxRecord", values: values),
          instance_double("InfluxDB2::FluxRecord", values: values),
          instance_double("InfluxDB2::FluxRecord", values: values)
        ]
      )
    }
  end

  let(:reliable_runs) do
    values = { "name" => "unstable spec", "status" => "failed", "file_path" => "some/spec.rb", "stage" => "create" }
    {
      0 => instance_double(
        "InfluxDB2::FluxTable",
        records: [
          instance_double("InfluxDB2::FluxRecord", values: { **values, "status" => "passed" }),
          instance_double("InfluxDB2::FluxRecord", values: values),
          instance_double("InfluxDB2::FluxRecord", values: values)
        ]
      )
    }
  end

  def flux_query(reliable:)
    <<~QUERY
      from(bucket: "e2e-test-stats")
        |> range(start: -#{range}d)
        |> filter(fn: (r) => r._measurement == "test-stats")
        |> filter(fn: (r) => r.run_type == "staging-full" or
          r.run_type == "staging-sanity" or
          r.run_type == "staging-sanity-no-admin" or
          r.run_type == "production-full" or
          r.run_type == "production-sanity" or
          r.run_type == "package-and-qa" or
          r.run_type == "nightly"
        )
        |> filter(fn: (r) => r.status != "pending" and
          r.merge_request == "false" and
          r.quarantined == "false" and
          r.reliable == "#{reliable}" and
          r._field == "id"
        )
        |> group(columns: ["name"])
    QUERY
  end

  def markdown_section(summary, result, stage, type)
    <<~SECTION.strip
      ```
      #{summary_table(summary, type)}
      ```

      ## #{stage}

      <details>
      <summary>Executions table</summary>

      ```
      #{table(result, ['NAME', 'RUNS', 'FAILURES', 'FAILURE RATE'], "Top #{type} specs in '#{stage}' stage for past #{range} days")}
      ```

      </details>
    SECTION
  end

  def summary_table(summary, type)
    table(summary, %w[STAGE COUNT], "#{type.capitalize} spec summary for past #{range} days".ljust(50))
  end

  def table(rows, headings, title)
    Terminal::Table.new(
      headings: headings,
      style: { all_separators: true },
      title: title,
      rows: rows
    )
  end

  def name_column(spec_name)
    name = "name: '#{spec_name}'"
    file = "file: 'spec.rb'".ljust(160)

    "#{name}\n#{file}"
  end

  before do
    stub_env("QA_INFLUXDB_URL", "url")
    stub_env("QA_INFLUXDB_TOKEN", "token")
    stub_env("SLACK_WEBHOOK", "slack_url")
    stub_env("CI_API_V4_URL", "gitlab_api_url")
    stub_env("GITLAB_ACCESS_TOKEN", "gitlab_token")

    allow(RestClient::Request).to receive(:execute).and_return(gitlab_response)
    allow(Slack::Notifier).to receive(:new).and_return(slack_notifier)
    allow(InfluxDB2::Client).to receive(:new).and_return(influx_client)

    allow(query_api).to receive(:query).with(query: flux_query(reliable: false)).and_return(runs)
    allow(query_api).to receive(:query).with(query: flux_query(reliable: true)).and_return(reliable_runs)
  end

  context "without report creation" do
    let(:create_issue) { "false" }

    it "does not create report issue", :aggregate_failures do
      expect { run }.to output.to_stdout

      expect(RestClient::Request).not_to have_received(:execute)
      expect(slack_notifier).not_to have_received(:post)
    end
  end

  context "with report creation" do
    let(:create_issue) { "true" }
    let(:issue_body) do
      <<~TXT.strip
        [[_TOC_]]

        # Candidates for promotion to reliable

        #{markdown_section([['manage', 1]], [[name_column('stable spec'), 3, 0, '0%']], 'manage', 'stable')}

        # Reliable specs with failures

        #{markdown_section([['create', 1]], [[name_column('unstable spec'), 3, 2, '66.67%']], 'create', 'unstable')}
      TXT
    end

    it "creates report issue", :aggregate_failures do
      expect { run }.to output.to_stdout

      expect(RestClient::Request).to have_received(:execute).with(
        method: :post,
        url: "gitlab_api_url/projects/278964/issues",
        verify_ssl: false,
        headers: { "PRIVATE-TOKEN" => "gitlab_token" },
        payload: {
          title: "Reliable spec report",
          description: issue_body,
          labels: "Quality,test"
        }
      )
      expect(slack_notifier).to have_received(:post).with(
        icon_emoji: ":tanuki-protect:",
        text: <<~TEXT
          ```#{summary_table([['manage', 1]], 'stable')}```
          ```#{summary_table([['create', 1]], 'unstable')}```

          #{issue_url}
        TEXT
      )
    end
  end

  context "with failure" do
    let(:create_issue) { "true" }

    before do
      allow(query_api).to receive(:query).and_raise("Connection error!")
    end

    it "notifies failure", :aggregate_failures do
      expect { expect { run }.to raise_error(SystemExit) }.to output.to_stdout

      expect(slack_notifier).to have_received(:post).with(
        icon_emoji: ":sadpanda:",
        text: "Reliable reporter failed to create report. Error: ```Connection error!```"
      )
    end
  end
end
