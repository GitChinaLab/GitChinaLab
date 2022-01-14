# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Manager do
  include StubENV

  let(:progress) { StringIO.new }

  subject { described_class.new(progress) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)
  end

  describe '#pack' do
    let(:expected_backup_contents) { %w(repositories db uploads.tar.gz builds.tar.gz artifacts.tar.gz pages.tar.gz lfs.tar.gz backup_information.yml) }
    let(:tar_file) { '1546300800_2019_01_01_12.3_gitlab_backup.tar' }
    let(:tar_system_options) { { out: [tar_file, 'w', Gitlab.config.backup.archive_permissions] } }
    let(:tar_cmdline) { ['tar', '-cf', '-', *expected_backup_contents, tar_system_options] }
    let(:backup_information) do
      {
        backup_created_at: Time.zone.parse('2019-01-01'),
        gitlab_version: '12.3'
      }
    end

    before do
      allow(ActiveRecord::Base.connection).to receive(:reconnect!)
      allow(Kernel).to receive(:system).and_return(true)
      allow(YAML).to receive(:load_file).and_return(backup_information)

      ::Backup::Manager::FOLDERS_TO_BACKUP.each do |folder|
        allow(Dir).to receive(:exist?).with(File.join(Gitlab.config.backup.path, folder)).and_return(true)
      end

      allow(subject).to receive(:backup_information).and_return(backup_information)
      allow(subject).to receive(:upload)
    end

    it 'executes tar' do
      subject.pack

      expect(Kernel).to have_received(:system).with(*tar_cmdline)
    end

    context 'when BACKUP is set' do
      let(:tar_file) { 'custom_gitlab_backup.tar' }

      it 'uses the given value as tar file name' do
        stub_env('BACKUP', '/ignored/path/custom')
        subject.pack

        expect(Kernel).to have_received(:system).with(*tar_cmdline)
      end
    end

    context 'when skipped is set in backup_information.yml' do
      let(:expected_backup_contents) { %w{db uploads.tar.gz builds.tar.gz artifacts.tar.gz pages.tar.gz lfs.tar.gz backup_information.yml} }
      let(:backup_information) do
        {
          backup_created_at: Time.zone.parse('2019-01-01'),
          gitlab_version: '12.3',
          skipped: ['repositories']
        }
      end

      it 'executes tar' do
        subject.pack

        expect(Kernel).to have_received(:system).with(*tar_cmdline)
      end
    end

    context 'when a directory does not exist' do
      let(:expected_backup_contents) { %w{db uploads.tar.gz builds.tar.gz artifacts.tar.gz pages.tar.gz lfs.tar.gz backup_information.yml} }

      before do
        expect(Dir).to receive(:exist?).with(File.join(Gitlab.config.backup.path, 'repositories')).and_return(false)
      end

      it 'executes tar' do
        subject.pack

        expect(Kernel).to have_received(:system).with(*tar_cmdline)
      end
    end
  end

  describe '#remove_tmp' do
    let(:path) { File.join(Gitlab.config.backup.path, 'tmp') }

    before do
      allow(FileUtils).to receive(:rm_rf).and_return(true)
    end

    it 'removes backups/tmp dir' do
      subject.remove_tmp

      expect(FileUtils).to have_received(:rm_rf).with(path)
    end

    it 'prints running task with a done confirmation' do
      subject.remove_tmp

      expect(progress).to have_received(:print).with('Deleting backups/tmp ... ')
      expect(progress).to have_received(:puts).with('done')
    end
  end

  describe '#remove_old' do
    let(:files) do
      [
        '1451606400_2016_01_01_1.2.3_gitlab_backup.tar',
        '1451520000_2015_12_31_4.5.6_gitlab_backup.tar',
        '1451520000_2015_12_31_4.5.6-pre_gitlab_backup.tar',
        '1451520000_2015_12_31_4.5.6-rc1_gitlab_backup.tar',
        '1451520000_2015_12_31_4.5.6-pre-ee_gitlab_backup.tar',
        '1451510000_2015_12_30_gitlab_backup.tar',
        '1450742400_2015_12_22_gitlab_backup.tar',
        '1449878400_gitlab_backup.tar',
        '1449014400_gitlab_backup.tar',
        'manual_gitlab_backup.tar'
      ]
    end

    before do
      allow(Dir).to receive(:chdir).and_yield
      allow(Dir).to receive(:glob).and_return(files)
      allow(FileUtils).to receive(:rm)
      allow(Time).to receive(:now).and_return(Time.utc(2016))
    end

    context 'when keep_time is zero' do
      before do
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(0)

        subject.remove_old
      end

      it 'removes no files' do
        expect(FileUtils).not_to have_received(:rm)
      end

      it 'prints a skipped message' do
        expect(progress).to have_received(:puts).with('skipping')
      end
    end

    context 'when no valid file is found' do
      let(:files) do
        [
          '14516064000_2016_01_01_1.2.3_gitlab_backup.tar',
          'foo_1451520000_2015_12_31_4.5.6_gitlab_backup.tar',
          '1451520000_2015_12_31_4.5.6-foo_gitlab_backup.tar'
        ]
      end

      before do
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(1)

        subject.remove_old
      end

      it 'removes no files' do
        expect(FileUtils).not_to have_received(:rm)
      end

      it 'prints a done message' do
        expect(progress).to have_received(:puts).with('done. (0 removed)')
      end
    end

    context 'when there are no files older than keep_time' do
      before do
        # Set to 30 days
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(2592000)

        subject.remove_old
      end

      it 'removes no files' do
        expect(FileUtils).not_to have_received(:rm)
      end

      it 'prints a done message' do
        expect(progress).to have_received(:puts).with('done. (0 removed)')
      end
    end

    context 'when keep_time is set to remove files' do
      before do
        # Set to 1 second
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(1)

        subject.remove_old
      end

      it 'removes matching files with a human-readable versioned timestamp' do
        expect(FileUtils).to have_received(:rm).with(files[1])
        expect(FileUtils).to have_received(:rm).with(files[2])
        expect(FileUtils).to have_received(:rm).with(files[3])
      end

      it 'removes matching files with a human-readable versioned timestamp with tagged EE' do
        expect(FileUtils).to have_received(:rm).with(files[4])
      end

      it 'removes matching files with a human-readable non-versioned timestamp' do
        expect(FileUtils).to have_received(:rm).with(files[5])
        expect(FileUtils).to have_received(:rm).with(files[6])
      end

      it 'removes matching files without a human-readable timestamp' do
        expect(FileUtils).to have_received(:rm).with(files[7])
        expect(FileUtils).to have_received(:rm).with(files[8])
      end

      it 'does not remove files that are not old enough' do
        expect(FileUtils).not_to have_received(:rm).with(files[0])
      end

      it 'does not remove non-matching files' do
        expect(FileUtils).not_to have_received(:rm).with(files[9])
      end

      it 'prints a done message' do
        expect(progress).to have_received(:puts).with('done. (8 removed)')
      end
    end

    context 'when removing a file fails' do
      let(:file) { files[1] }
      let(:message) { "Permission denied @ unlink_internal - #{file}" }

      before do
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(1)
        allow(FileUtils).to receive(:rm).with(file).and_raise(Errno::EACCES, message)

        subject.remove_old
      end

      it 'removes the remaining expected files' do
        expect(FileUtils).to have_received(:rm).with(files[4])
        expect(FileUtils).to have_received(:rm).with(files[5])
        expect(FileUtils).to have_received(:rm).with(files[6])
        expect(FileUtils).to have_received(:rm).with(files[7])
        expect(FileUtils).to have_received(:rm).with(files[8])
      end

      it 'sets the correct removed count' do
        expect(progress).to have_received(:puts).with('done. (7 removed)')
      end

      it 'prints the error from file that could not be removed' do
        expect(progress).to have_received(:puts).with(a_string_matching(message))
      end
    end
  end

  describe 'verify_backup_version' do
    context 'on version mismatch' do
      let(:gitlab_version) { Gitlab::VERSION }

      it 'stops the process' do
        allow(YAML).to receive(:load_file)
          .and_return({ gitlab_version: "not #{gitlab_version}" })

        expect { subject.verify_backup_version }.to raise_error SystemExit
      end
    end

    context 'on version match' do
      let(:gitlab_version) { Gitlab::VERSION }

      it 'does nothing' do
        allow(YAML).to receive(:load_file)
          .and_return({ gitlab_version: "#{gitlab_version}" })

        expect { subject.verify_backup_version }.not_to raise_error
      end
    end
  end

  describe '#unpack' do
    context 'when there are no backup files in the directory' do
      before do
        allow(Dir).to receive(:glob).and_return([])
      end

      it 'fails the operation and prints an error' do
        expect { subject.unpack }.to raise_error SystemExit
        expect(progress).to have_received(:puts)
          .with(a_string_matching('No backups found'))
      end
    end

    context 'when there are two backup files in the directory and BACKUP variable is not set' do
      before do
        allow(Dir).to receive(:glob).and_return(
          [
            '1451606400_2016_01_01_1.2.3_gitlab_backup.tar',
            '1451520000_2015_12_31_gitlab_backup.tar'
          ]
        )
      end

      it 'prints the list of available backups' do
        expect { subject.unpack }.to raise_error SystemExit
        expect(progress).to have_received(:puts)
          .with(a_string_matching('1451606400_2016_01_01_1.2.3\n 1451520000_2015_12_31'))
      end

      it 'fails the operation and prints an error' do
        expect { subject.unpack }.to raise_error SystemExit
        expect(progress).to have_received(:puts)
          .with(a_string_matching('Found more than one backup'))
      end
    end

    context 'when BACKUP variable is set to a non-existing file' do
      before do
        allow(Dir).to receive(:glob).and_return(
          [
            '1451606400_2016_01_01_gitlab_backup.tar'
          ]
        )
        allow(File).to receive(:exist?).and_return(false)

        stub_env('BACKUP', 'wrong')
      end

      it 'fails the operation and prints an error' do
        expect { subject.unpack }.to raise_error SystemExit
        expect(File).to have_received(:exist?).with('wrong_gitlab_backup.tar')
        expect(progress).to have_received(:puts)
          .with(a_string_matching('The backup file wrong_gitlab_backup.tar does not exist'))
      end
    end

    context 'when BACKUP variable is set to a correct file' do
      before do
        allow(Dir).to receive(:glob).and_return(
          [
            '1451606400_2016_01_01_1.2.3_gitlab_backup.tar'
          ]
        )
        allow(File).to receive(:exist?).and_return(true)
        allow(Kernel).to receive(:system).and_return(true)
        allow(YAML).to receive(:load_file).and_return(gitlab_version: Gitlab::VERSION)

        stub_env('BACKUP', '/ignored/path/1451606400_2016_01_01_1.2.3')
      end

      it 'unpacks the file' do
        subject.unpack

        expect(Kernel).to have_received(:system)
          .with("tar", "-xf", "1451606400_2016_01_01_1.2.3_gitlab_backup.tar")
        expect(progress).to have_received(:puts).with(a_string_matching('done'))
      end
    end

    context 'when there is a non-tarred backup in the directory' do
      before do
        allow(Dir).to receive(:glob).and_return(
          [
            'backup_information.yml'
          ]
        )
        allow(File).to receive(:exist?).and_return(true)
      end

      it 'selects the non-tarred backup to restore from' do
        expect(Kernel).not_to receive(:system)

        subject.unpack

        expect(progress).to have_received(:puts)
          .with(a_string_matching('Non tarred backup found '))
      end
    end
  end

  describe '#upload' do
    let(:backup_file) { Tempfile.new('backup', Gitlab.config.backup.path) }
    let(:backup_filename) { File.basename(backup_file.path) }

    before do
      allow(subject).to receive(:tar_file).and_return(backup_filename)

      stub_backup_setting(
        upload: {
          connection: {
            provider: 'AWS',
            aws_access_key_id: 'id',
            aws_secret_access_key: 'secret'
          },
          remote_directory: 'directory',
          multipart_chunk_size: 104857600,
          encryption: nil,
          encryption_key: nil,
          storage_class: nil
        }
      )

      Fog.mock!

      # the Fog mock only knows about directories we create explicitly
      connection = ::Fog::Storage.new(Gitlab.config.backup.upload.connection.symbolize_keys)
      connection.directories.create(key: Gitlab.config.backup.upload.remote_directory)
    end

    context 'target path' do
      it 'uses the tar filename by default' do
        expect_any_instance_of(Fog::Collection).to receive(:create)
          .with(hash_including(key: backup_filename, public: false))
          .and_return(true)

        subject.upload
      end

      it 'adds the DIRECTORY environment variable if present' do
        stub_env('DIRECTORY', 'daily')

        expect_any_instance_of(Fog::Collection).to receive(:create)
          .with(hash_including(key: "daily/#{backup_filename}", public: false))
          .and_return(true)

        subject.upload
      end
    end

    context 'with AWS with server side encryption' do
      let(:connection) { ::Fog::Storage.new(Gitlab.config.backup.upload.connection.symbolize_keys) }
      let(:encryption_key) { nil }
      let(:encryption) { nil }
      let(:storage_options) { nil }

      before do
        stub_backup_setting(
          upload: {
            connection: {
              provider: 'AWS',
              aws_access_key_id: 'AWS_ACCESS_KEY_ID',
              aws_secret_access_key: 'AWS_SECRET_ACCESS_KEY'
            },
            remote_directory: 'directory',
            multipart_chunk_size: Gitlab.config.backup.upload.multipart_chunk_size,
            encryption: encryption,
            encryption_key: encryption_key,
            storage_options: storage_options,
            storage_class: nil
          }
        )

        connection.directories.create(key: Gitlab.config.backup.upload.remote_directory)
      end

      context 'with SSE-S3 without using storage_options' do
        let(:encryption) { 'AES256' }

        it 'sets encryption attributes' do
          result = subject.upload

          expect(result.key).to be_present
          expect(result.encryption).to eq('AES256')
          expect(result.encryption_key).to be_nil
          expect(result.kms_key_id).to be_nil
        end
      end

      context 'with SSE-C (customer-provided keys) options' do
        let(:encryption) { 'AES256' }
        let(:encryption_key) { SecureRandom.hex }

        it 'sets encryption attributes' do
          result = subject.upload

          expect(result.key).to be_present
          expect(result.encryption).to eq(encryption)
          expect(result.encryption_key).to eq(encryption_key)
          expect(result.kms_key_id).to be_nil
        end
      end

      context 'with SSE-KMS options' do
        let(:storage_options) do
          {
            server_side_encryption: 'aws:kms',
            server_side_encryption_kms_key_id: 'arn:aws:kms:12345'
          }
        end

        it 'sets encryption attributes' do
          result = subject.upload

          expect(result.key).to be_present
          expect(result.encryption).to eq('aws:kms')
          expect(result.kms_key_id).to eq('arn:aws:kms:12345')
        end
      end
    end

    context 'with Google provider' do
      before do
        stub_backup_setting(
          upload: {
            connection: {
              provider: 'Google',
              google_storage_access_key_id: 'test-access-id',
              google_storage_secret_access_key: 'secret'
            },
            remote_directory: 'directory',
            multipart_chunk_size: Gitlab.config.backup.upload.multipart_chunk_size,
            encryption: nil,
            encryption_key: nil,
            storage_class: nil
          }
        )

        connection = ::Fog::Storage.new(Gitlab.config.backup.upload.connection.symbolize_keys)
        connection.directories.create(key: Gitlab.config.backup.upload.remote_directory)
      end

      it 'does not attempt to set ACL' do
        expect_any_instance_of(Fog::Collection).to receive(:create)
          .with(hash_excluding(public: false))
          .and_return(true)

        subject.upload
      end
    end

    context 'with AzureRM provider' do
      before do
        stub_backup_setting(
          upload: {
            connection: {
              provider: 'AzureRM',
              azure_storage_account_name: 'test-access-id',
              azure_storage_access_key: 'secret'
            },
            remote_directory: 'directory',
            multipart_chunk_size: nil,
            encryption: nil,
            encryption_key: nil,
            storage_class: nil
          }
        )
      end

      it 'loads the provider' do
        expect { subject.upload }.not_to raise_error
      end
    end
  end
end
