module TivoHMO
  module Adapters
    module StreamIO

      # Extracts some basic metadata using the streamio gem
      class Metadata < TivoHMO::API::Metadata
        include GemLogger::LoggerSupport

        attr_accessor :movie

        def initialize(item)
          super(item)
          begin
            self.movie = FFMPEG::Movie.new(item.identifier)
            self.duration = movie.duration
          rescue => e
            logger.error "Failed to read movie metadata: #{e}"
          end
        end

      end

    end
  end
end
