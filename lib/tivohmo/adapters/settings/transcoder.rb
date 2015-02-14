module TivoHMO
  module Adapters
    module Settings


      # Dummy transcoder
      class Transcoder
        include TivoHMO::API::Transcoder
        include GemLogger::LoggerSupport

        def transcode(writeable_io, format="video/x-tivo-mpeg")
          nil
        end

        def transcoder_options(format="video/x-tivo-mpeg")
          {}
        end

      end

    end
  end
end
