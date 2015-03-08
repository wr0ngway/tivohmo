require 'active_support/core_ext/string/inflections'
require 'tivohmo/adapters/streamio'
require 'listen'

module TivoHMO
  module Adapters
    module Filesystem

      # An Application based on a filesystem
      class Application < FolderContainer
        include TivoHMO::API::Application
        include GemLogger::LoggerSupport
        include MonitorMixin

        def initialize(identifier)
          super(identifier)
          self.metadata_class = TivoHMO::Adapters::StreamIO::Metadata
          self.transcoder_class = TivoHMO::Adapters::StreamIO::Transcoder

          setup_change_listener
        end

        private

        def setup_change_listener
          logger.debug "Setting up change listener on #{identifier}"

          fq_path = File.realdirpath(identifier)
          listener = Listen.to(fq_path) do |modified, added, removed|
            logger.debug "Detected filesystem change on #{identifier}"

            dirs = (modified + added + removed).flatten.collect do |path|
              relative_path = path.sub(fq_path, '')
              relative_dir = File.dirname(relative_path).sub(/^\//, '')
            end
            dirs.uniq!

            dirs.each do |dir|
              begin
                logger.debug "Handling filesystem change: #{dir.inspect}"
                title_path = dir.split('/').collect(&:titleize).join('/')
                # TODO fix Node#find
                container = title_path.blank? ? self : find(title_path)
                container.refresh if container
              rescue Exception => e
                logger.log_exception(e, "Ignoring exception in filesystem refresh: #{path}")
              end
            end

            logger.debug "Completed filesystem refresh on #{identifier}"
          end

          listener.start
        end

      end

    end
  end
end
