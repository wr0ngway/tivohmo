module TivoHMO
  module Adapters
    module Plex

      class Transcoder < TivoHMO::API::Transcoder
        include GemLogger::LoggerSupport

        def transcode(writeable_io)
          raise NotImplementedError
        end

      end

    end
  end
end
