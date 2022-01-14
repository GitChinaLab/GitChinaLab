# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::ClusterPresenter do
  include Gitlab::Routing.url_helpers

  let(:cluster) { create(:cluster, :provided_by_gcp, :project) }
  let(:user) { create(:user) }

  subject(:presenter) do
    described_class.new(cluster, current_user: user)
  end

  it 'inherits from Gitlab::View::Presenter::Delegated' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Delegated)
  end

  describe '#initialize' do
    it 'takes a cluster and optional params' do
      expect { presenter }.not_to raise_error
    end

    it 'exposes cluster' do
      expect(presenter.cluster).to eq(cluster)
    end

    it 'forwards missing methods to cluster' do
      expect(presenter.status).to eq(cluster.status)
    end
  end

  describe '#provider_label' do
    let(:cluster) { create(:cluster, provider_type: provider_type) }

    subject { described_class.new(cluster).provider_label }

    context 'AWS provider' do
      let(:provider_type) { :aws }

      it { is_expected.to eq('Elastic Kubernetes Service') }
    end

    context 'GCP provider' do
      let(:provider_type) { :gcp }

      it { is_expected.to eq('Google Kubernetes Engine') }
    end
  end

  describe '#provider_management_url' do
    let(:cluster) { provider.cluster }

    subject { described_class.new(cluster).provider_management_url }

    context 'AWS provider' do
      let(:provider) { create(:cluster_provider_aws) }

      it { is_expected.to include(provider.region) }
      it { is_expected.to include(cluster.name) }
    end

    context 'GCP provider' do
      let(:provider) { create(:cluster_provider_gcp) }

      it { is_expected.to include(provider.zone) }
      it { is_expected.to include(cluster.name) }
    end
  end

  describe '#show_path' do
    subject { described_class.new(cluster).show_path }

    context 'project_type cluster' do
      let(:project) { cluster.project }

      it { is_expected.to eq(project_cluster_path(project, cluster)) }
    end

    context 'group_type cluster' do
      let(:group) { cluster.group }
      let(:cluster) { create(:cluster, :provided_by_gcp, :group) }

      it { is_expected.to eq(group_cluster_path(group, cluster)) }
    end

    context 'instance_type cluster' do
      let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

      it { is_expected.to eq(admin_cluster_path(cluster)) }
    end
  end

  describe '#read_only_kubernetes_platform_fields?' do
    subject { described_class.new(cluster).read_only_kubernetes_platform_fields? }

    context 'with a user-provided cluster' do
      let(:cluster) { build_stubbed(:cluster, :provided_by_user) }

      it { is_expected.to be_falsy }
    end

    context 'with a GCP-provided cluster' do
      let(:cluster) { build_stubbed(:cluster, :provided_by_gcp) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#health_data' do
    shared_examples 'cluster health data' do
      let(:user) { create(:user) }
      let(:cluster_presenter) { cluster.present(current_user: user) }

      let(:clusterable_presenter) do
        ClusterablePresenter.fabricate(clusterable, current_user: user)
      end

      subject { cluster_presenter.health_data(clusterable_presenter) }

      it do
        is_expected.to include('clusters-path': clusterable_presenter.index_path,
                             'dashboard-endpoint': clusterable_presenter.metrics_dashboard_path(cluster),
                             'documentation-path': help_page_path('user/project/clusters/index', anchor: 'monitoring-your-kubernetes-cluster'),
                             'add-dashboard-documentation-path': help_page_path('operations/metrics/dashboards/index.md', anchor: 'add-a-new-dashboard-to-your-project'),
                             'empty-getting-started-svg-path': match_asset_path('/assets/illustrations/monitoring/getting_started.svg'),
                             'empty-loading-svg-path': match_asset_path('/assets/illustrations/monitoring/loading.svg'),
                             'empty-no-data-svg-path': match_asset_path('/assets/illustrations/monitoring/no_data.svg'),
                             'empty-no-data-small-svg-path': match_asset_path('illustrations/chart-empty-state-small.svg'),
                             'empty-unable-to-connect-svg-path': match_asset_path('/assets/illustrations/monitoring/unable_to_connect.svg'),
                             'settings-path': '',
                             'project-path': '',
                             'tags-path': '')
      end
    end

    context 'with project cluster' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:clusterable) { cluster.project }

      it_behaves_like 'cluster health data'
    end

    context 'with group cluster' do
      let(:cluster) { create(:cluster, :group, :provided_by_gcp) }
      let(:clusterable) { cluster.group }

      it_behaves_like 'cluster health data'
    end
  end

  describe '#gitlab_managed_apps_logs_path' do
    context 'user can read logs' do
      let(:project) { cluster.project }

      before do
        project.add_maintainer(user)
      end

      it 'returns path to logs' do
        expect(presenter.gitlab_managed_apps_logs_path).to eq k8s_project_logs_path(project, cluster_id: cluster.id, format: :json)
      end

      context 'cluster has elastic stack integration enabled' do
        before do
          create(:clusters_integrations_elastic_stack, cluster: cluster)
        end

        it 'returns path to logs' do
          expect(presenter.gitlab_managed_apps_logs_path).to eq elasticsearch_project_logs_path(project, cluster_id: cluster.id, format: :json)
        end
      end
    end

    context 'group cluster' do
      let(:cluster) { create(:cluster, cluster_type: :group_type, groups: [group]) }
      let(:group) { create(:group, name: 'Foo') }

      context 'user can read logs' do
        before do
          group.add_maintainer(user)
        end

        context 'there are projects within group' do
          let!(:project) { create(:project, namespace: group) }

          it 'returns path to logs' do
            expect(presenter.gitlab_managed_apps_logs_path).to eq k8s_project_logs_path(project, cluster_id: cluster.id, format: :json)
          end
        end

        context 'there are no projects within group' do
          it 'returns nil' do
            expect(presenter.gitlab_managed_apps_logs_path).to be_nil
          end
        end
      end
    end

    context 'instance cluster' do
      let(:cluster) { create(:cluster, cluster_type: :instance_type) }
      let!(:project) { create(:project) }
      let(:user) { create(:admin) }

      before do
        project.add_maintainer(user)
        stub_application_setting(admin_mode: false)
      end

      context 'user can read logs' do
        it 'returns path to logs' do
          expect(presenter.gitlab_managed_apps_logs_path).to eq k8s_project_logs_path(project, cluster_id: cluster.id, format: :json)
        end
      end
    end

    context 'user can NOT read logs' do
      let(:cluster) { create(:cluster, cluster_type: :instance_type) }
      let!(:project) { create(:project) }

      before do
        project.add_developer(user)
        stub_application_setting(admin_mode: false)
      end

      it 'returns nil' do
        expect(presenter.gitlab_managed_apps_logs_path).to be_nil
      end
    end
  end
end
