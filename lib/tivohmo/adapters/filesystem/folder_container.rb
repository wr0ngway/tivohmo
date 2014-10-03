require 'active_support/core_ext/string/inflections'
require 'listen'

module TivoHMO
  module Adapters
    module Filesystem

      # A Container based on a filesystem folder
      class FolderContainer < TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

        def initialize(identifier, exts: %w[avi mp4 mpg mkv])
          full_path = File.expand_path(identifier)
          raise ArgumentError, "Must provide an existing directory: #{full_path}" unless File.directory?(full_path)

          super(full_path)

          @exts = exts.collect {|e| e.starts_with?('.') ? e : ".#{e}" }
          self.title = File.basename(self.identifier)
          self.content_type = "x-container/tivo-videos"
          self.modified_at = File.mtime(self.identifier)
          self.created_at = File.ctime(self.identifier)

          setup_change_listener
        end

        def children
          synchronize do
            if super.blank?
              folders = []
              files = []

              Dir["#{self.identifier}/*"].each do |path|
                if File.directory?(path)
                  folders << FolderContainer.new(path, exts: @exts)
                elsif belongs?(path)
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
          @listener = Listen.to(identifier) do |modified, added, removed|
            logger.info "Detected filesystem change on #{identifier}"
            logger.debug "modified absolute path: #{modified}"
            logger.debug "added absolute path: #{added}"
            logger.debug "removed absolute path: #{removed}"

            # TODO: be more intelligent instead of just wiping children to cause the refresh
            self.children = [] if added.present? or modified.present?

            # cleanup - not strictly correct as this listener won't necessarily get triggered
            # if self is removed from the parent
            @listener.stop unless root.find(title_path)
          end
          @listener.start
        end

        def belongs?(path)
          ext = File.extname(path)
          @exts.include?(ext)
        end
      end

    end
  end
end