require 'active_support/core_ext/string/inflections'
require 'listen'

module TivoHMO
  module Adapters
    module Filesystem

      # A Container based on a filesystem folder
      class FolderContainer
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_accessor :full_path,
                      :allowed_item_types,
                      :allowed_item_extensions

        def initialize(identifier)
          self.full_path = File.expand_path(identifier)
          raise ArgumentError, "Must provide an existing directory: #{full_path}" unless File.directory?(full_path)

          super(full_path)

          self.allowed_item_types = %i[file dir]
          self.allowed_item_extensions = %w[avi mp4 mpg mkv]

          self.title = File.basename(self.identifier)
          self.modified_at = File.mtime(self.identifier)
          self.created_at = File.ctime(self.identifier)

          setup_change_listener
        end

        def children
          synchronize do
            if super.blank?
              folders = []
              files = []

              Dir["#{self.full_path}/*"].each do |path|
                if allowed_container?(path)
                  folders << FolderContainer.new(path)
                elsif allowed_item?(path)
                  files << FileItem.new(path)
                else
                  logger.debug "Ignoring: #{path}"
                end
              end

              (folders + files).each {|c| add_child(c) }
            end
          end

          super
        end

        protected

        def setup_change_listener
          logger.debug "Setting up change listener on #{identifier}"
          @listener = Listen.to(identifier) do |modified, added, removed|
            logger.debug "Detected filesystem change on #{identifier}"
            logger.debug "modified absolute path: #{modified}"
            logger.debug "added absolute path: #{added}"
            logger.debug "removed absolute path: #{removed}"

            # TODO: be more intelligent instead of just wiping children to cause the refresh
            self.refresh

            # cleanup - not strictly correct as this listener won't necessarily get triggered
            # if self is removed from the parent
            @listener.stop unless root.find(title_path)
            logger.debug "Completed filesystem refresh on #{identifier}"

          end
          logger.debug "Starting change listener on #{identifier}"
          @listener.start
          logger.debug "Change listener started on #{identifier}"
        end

        def allowed_container?(path)
          File.directory?(path) && allowed_item_types.include?(:dir)
        end

        def allowed_item?(path)
          ext = File.extname(path).gsub(/^./, '')
          File.file?(path) &&
              allowed_item_types.include?(:file) &&
              allowed_item_extensions.include?(ext)
        end

      end

    end
  end
end
