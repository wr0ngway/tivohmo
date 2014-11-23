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
            self.duration = (item.delegate.duration.to_i / 1000).to_i

            # plex 0-10 => tivo 1-7 for value, 0-4 in .5 increments for name
            plex_rating = item.delegate.rating.to_f
            rating_value = (plex_rating / 10 * 6).round
            rating_name = [1, 1.5, 2, 2.5, 3, 3.5, 4][rating_value]
            self.star_rating = {name: rating_name, value: rating_value + 1}

          rescue => e
            logger.error "Failed to read plex metadata: #{e}"
          end
        end

      end

    end
  end
end
