require 'active_support/core_ext/string/inflections'
require 'tivohmo/adapters/streamio'

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
        end
      end

    end
  end
end
