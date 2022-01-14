# frozen_string_literal: true

module Projects
  module HashedStorage
    # Returned when repository can't be made read-only because there is already a git transfer in progress
    RepositoryInUseError = Class.new(StandardError)

    class BaseRepositoryService < BaseService
      include Gitlab::ShellAdapter

      attr_reader :old_disk_path, :new_disk_path, :old_storage_version,
                  :logger, :move_wiki, :move_design

      def initialize(project:, old_disk_path:, logger: nil)
        @project = project
        @logger = logger || Gitlab::AppLogger
        @old_disk_path = old_disk_path
        @move_wiki = has_wiki?
        @move_design = has_design?
      end

      protected

      def has_wiki?
        gitlab_shell.repository_exists?(project.repository_storage, "#{old_wiki_disk_path}.git")
      end

      def has_design?
        gitlab_shell.repository_exists?(project.repository_storage, "#{old_design_disk_path}.git")
      end

      def move_repository(from_name, to_name)
        from_exists = gitlab_shell.repository_exists?(project.repository_storage, "#{from_name}.git")
        to_exists = gitlab_shell.repository_exists?(project.repository_storage, "#{to_name}.git")

        # If we don't find the repository on either original or target we should log that as it could be an issue if the
        # project was not originally empty.
        if !from_exists && !to_exists
          logger.warn "Can't find a repository on either source or target paths for #{project.full_path} (ID=#{project.id}) ..."

          # We return true so we still reflect the change in the database.
          # Next time the repository is (re)created it will be under the new storage layout
          return true
        elsif !from_exists
          # Repository have been moved already.
          return true
        end

        gitlab_shell.mv_repository(project.repository_storage, from_name, to_name).tap do |moved|
          if moved
            logger.info("Repository moved from '#{from_name}' to '#{to_name}' (PROJECT_ID=#{project.id})")
          else
            logger.error("Repository cannot be moved from '#{from_name}' to '#{to_name}' (PROJECT_ID=#{project.id})")
          end
        end
      end

      def move_repositories
        result = move_repository(old_disk_path, new_disk_path)
        project.reload_repository!

        if move_wiki
          result &&= move_repository(old_wiki_disk_path, new_wiki_disk_path)
          project.clear_memoization(:wiki)
        end

        if move_design
          result &&= move_repository(old_design_disk_path, new_design_disk_path)
          project.clear_memoization(:design_repository)
        end

        result
      end

      def rollback_folder_move
        move_repository(new_disk_path, old_disk_path)
        move_repository(new_wiki_disk_path, old_wiki_disk_path)
        move_repository(new_design_disk_path, old_design_disk_path) if move_design
      end

      def try_to_set_repository_read_only!
        project.set_repository_read_only!
      rescue Project::RepositoryReadOnlyError => err
        migration_error = "Target repository '#{old_disk_path}' cannot be made read-only: #{err.message}"
        logger.error migration_error

        raise RepositoryInUseError, migration_error
      end

      def wiki_path_suffix
        @wiki_path_suffix ||= Gitlab::GlRepository::WIKI.path_suffix
      end

      def old_wiki_disk_path
        @old_wiki_disk_path ||= "#{old_disk_path}#{wiki_path_suffix}"
      end

      def new_wiki_disk_path
        @new_wiki_disk_path ||= "#{new_disk_path}#{wiki_path_suffix}"
      end

      def design_path_suffix
        @design_path_suffix ||= ::Gitlab::GlRepository::DESIGN.path_suffix
      end

      def old_design_disk_path
        @old_design_disk_path ||= "#{old_disk_path}#{design_path_suffix}"
      end

      def new_design_disk_path
        @new_design_disk_path ||= "#{new_disk_path}#{design_path_suffix}"
      end
    end
  end
end
