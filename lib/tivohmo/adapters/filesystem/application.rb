require 'active_support/core_ext/string/inflections'
require 'tivohmo/adapters/streamio'

module TivoHMO
  module Adapters
    module Filesystem

      # An Application based on a filesystem
      class Application < TivoHMO::API::Application
        include GemLogger::LoggerSupport

        def initialize(identifier)
          super
          self.container_class = TivoHMO::Adapters::Filesystem::FolderContainer
          self.metadata_class = TivoHMO::Adapters::StreamIO::Metadata
          self.transcoder_class = TivoHMO::Adapters::StreamIO::Transcoder
          self.content_type = "x-container/tivo-videos"
        end
      end

    end
  end
end
