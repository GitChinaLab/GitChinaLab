# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::DesignRepoRestorer do
  include GitHelpers

  describe 'bundle a design Git repo' do
    let(:user) { create(:user) }
    let!(:project_with_design_repo) { create(:project, :design_repo) }
    let!(:project) { create(:project) }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
    let(:shared) { project.import_export_shared }
    let(:bundler) { Gitlab::ImportExport::DesignRepoSaver.new(exportable: project_with_design_repo, shared: shared) }
    let(:bundle_path) { File.join(shared.export_path, Gitlab::ImportExport.design_repo_bundle_filename) }
    let(:restorer) do
      described_class.new(path_to_bundle: bundle_path,
                          shared: shared,
                          importable: project)
    end

    before do
      allow_next_instance_of(Gitlab::ImportExport) do |instance|
        allow(instance).to receive(:storage_path).and_return(export_path)
      end

      bundler.save
    end

    after do
      FileUtils.rm_rf(export_path)
      Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        FileUtils.rm_rf(project_with_design_repo.design_repository.path_to_repo)
        FileUtils.rm_rf(project.design_repository.path_to_repo)
      end
    end

    it 'restores the repo successfully' do
      expect(restorer.restore).to eq(true)
    end
  end
end
