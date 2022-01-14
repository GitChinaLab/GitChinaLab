# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFileUploader do
  {
    package_file: %r[^\h{2}/\h{2}/\h{64}/packages/\d+/files/\d+$],
    debian_package_file: %r[^\h{2}/\h{2}/\h{64}/packages/debian/files/\d+$]
  }.each do |factory, store_dir_regex|
    context factory.to_s do
      let(:package_file) { create(factory) } # rubocop:disable Rails/SaveBang
      let(:uploader) { described_class.new(package_file, :file) }
      let(:path) { Gitlab.config.packages.storage_path }

      subject { uploader }

      it_behaves_like "builds correct paths",
                      store_dir: store_dir_regex,
                      cache_dir: %r[/packages/tmp/cache],
                      work_dir: %r[/packages/tmp/work]

      context 'object store is remote' do
        before do
          stub_package_file_object_storage
        end

        include_context 'with storage', described_class::Store::REMOTE

        it_behaves_like "builds correct paths",
                        store_dir: store_dir_regex
      end

      describe 'remote file' do
        let(:package_file) { create(factory, :object_storage) }

        context 'with object storage enabled' do
          before do
            stub_package_file_object_storage
          end

          it 'can store file remotely' do
            allow(ObjectStorage::BackgroundMoveWorker).to receive(:perform_async)

            package_file

            expect(package_file.file_store).to eq(described_class::Store::REMOTE)
            expect(package_file.file.path).not_to be_blank
          end
        end
      end
    end
  end
end
