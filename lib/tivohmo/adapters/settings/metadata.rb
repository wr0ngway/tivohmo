module TivoHMO
  module Adapters
    module Settings

      # Dummy metadata
      class Metadata
        include TivoHMO::API::Metadata
        include GemLogger::LoggerSupport

        attr_accessor :item_detail_callback

        def initialize(item)
          super(item)
        end

        # hack - star_rating only gets called when viewing item_detail
        def star_rating
          item_detail_callback.try(:call, self)
          return nil
        end

      end

    end
  end
end
