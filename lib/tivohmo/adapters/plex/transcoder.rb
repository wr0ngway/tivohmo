require 'tivohmo/adapters/streamio'

module TivoHMO
  module Adapters
    module Plex

      class Transcoder < TivoHMO::Adapters::StreamIO::Transcoder
        include GemLogger::LoggerSupport

        def initialize(item)
          super(item)
        end

        def transcode(writeable_io, format="video/x-tivo-mpeg")
          # TODO: mark as watched in plex
          super
        end

      end

    end
  end
end
