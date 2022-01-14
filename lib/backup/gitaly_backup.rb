# frozen_string_literal: true

module Backup
  # Backup and restores repositories using gitaly-backup
  class GitalyBackup
    def initialize(progress, parallel: nil, parallel_storage: nil)
      @progress = progress
      @parallel = parallel
      @parallel_storage = parallel_storage
    end

    def start(type)
      raise Error, 'already started' if started?

      command = case type
                when :create
                  'create'
                when :restore
                  'restore'
                else
                  raise Error, "unknown backup type: #{type}"
                end

      args = []
      args += ['-parallel', @parallel.to_s] if @parallel
      args += ['-parallel-storage', @parallel_storage.to_s] if @parallel_storage

      @stdin, stdout, @thread = Open3.popen2(build_env, bin_path, command, '-path', backup_repos_path, *args)

      @out_reader = Thread.new do
        IO.copy_stream(stdout, @progress)
      end
    end

    def wait
      return unless started?

      @stdin.close
      [@thread, @out_reader].each(&:join)
      status =  @thread.value

      @thread = nil

      raise Error, "gitaly-backup exit status #{status.exitstatus}" if status.exitstatus != 0
    end

    def enqueue(container, repo_type)
      raise Error, 'not started' unless started?

      repository = repo_type.repository_for(container)

      @stdin.puts({
        storage_name: repository.storage,
        relative_path: repository.relative_path,
        gl_project_path: repository.gl_project_path,
        always_create: repo_type.project?
      }.merge(Gitlab::GitalyClient.connection_data(repository.storage)).to_json)
    end

    def parallel_enqueue?
      false
    end

    private

    def build_env
      {
        'SSL_CERT_FILE' => OpenSSL::X509::DEFAULT_CERT_FILE,
        'SSL_CERT_DIR'  => OpenSSL::X509::DEFAULT_CERT_DIR
      }.merge(ENV)
    end

    def started?
      @thread.present?
    end

    def backup_repos_path
      File.absolute_path(File.join(Gitlab.config.backup.path, 'repositories'))
    end

    def bin_path
      File.absolute_path(Gitlab.config.backup.gitaly_backup_path)
    end
  end
end
