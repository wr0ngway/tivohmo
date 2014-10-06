module TivoHMO
  module Adapters
    module Plex

      class Metadata
        include TivoHMO::API::Metadata
        include GemLogger::LoggerSupport

        def initialize(item)
          super

          begin
            self.description = item.delegate.summary
            self.duration = item.delegate.duration.to_i
          rescue => e
            logger.error "Failed to read plex metadata: #{e}"
          end
        end

      end

    end
  end
end
