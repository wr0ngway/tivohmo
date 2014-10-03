module TivoHMO
  module Adapters
    module Plex

      # Extracts some basic metadata using the streamio gem
      class Metadata < TivoHMO::API::Metadata
        include GemLogger::LoggerSupport

        def initialize(item)
          super

          begin
            self.duration = item.delegate.duration.to_i
            self.description = item.delegate.summary
          rescue => e
            logger.error "Failed to read plex metadata: #{e}"
          end
        end

      end

    end
  end
end
