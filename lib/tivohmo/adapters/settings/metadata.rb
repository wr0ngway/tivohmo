module TivoHMO
  module Adapters
    module Settings

      # Dummy metadata
      class Metadata
        include TivoHMO::API::Metadata
        include GemLogger::LoggerSupport

        def initialize(item)
          super(item)
        end

      end

    end
  end
end
