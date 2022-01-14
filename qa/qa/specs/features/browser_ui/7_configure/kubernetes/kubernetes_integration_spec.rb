# frozen_string_literal: true

module QA
  RSpec.describe 'Configure', except: { job: 'review-qa-*' } do
    describe 'Kubernetes Cluster Integration', :orchestrated, :requires_admin, :skip_live_env do
      context 'Project Clusters' do
        let!(:cluster) { Service::KubernetesCluster.new(provider_class: Service::ClusterProvider::K3s).create! }
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'project-with-k8s'
            project.description = 'Project with Kubernetes cluster integration'
          end
        end

        before do
          Flow::Login.sign_in_as_admin
        end

        after do
          cluster.remove!
        end

        it 'can create and associate a project cluster', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348062' do
          Resource::KubernetesCluster::ProjectCluster.fabricate_via_browser_ui! do |k8s_cluster|
            k8s_cluster.project = project
            k8s_cluster.cluster = cluster
          end.project.visit!

          Page::Project::Menu.perform(&:go_to_infrastructure_kubernetes)

          Page::Project::Infrastructure::Kubernetes::Index.perform do |index|
            expect(index).to have_cluster(cluster)
          end
        end
      end
    end
  end
end
