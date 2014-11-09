require 'tivohmo/adapters/streamio'

module TivoHMO
  module Adapters
    module Plex

      class Transcoder < TivoHMO::Adapters::StreamIO::Transcoder
        include GemLogger::LoggerSupport

        def initialize(item)
          super(item)
          self.source_filename = CGI.unescape(item.delegate.medias.first.parts.first.file)
        end

      end

    end
  end
end
