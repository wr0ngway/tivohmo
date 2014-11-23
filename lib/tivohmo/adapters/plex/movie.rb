module TivoHMO
  module Adapters
    module Plex

      class Movie
        include TivoHMO::API::Item
        include GemLogger::LoggerSupport

        attr_reader :delegate

        def initialize(delegate)
          # delegate is a Plex::Movie
          @delegate = delegate

          super(delegate.key)

          self.title = delegate.title
          self.modified_at = Time.at(delegate.updated_at.to_i)
          self.created_at = Time.at(delegate.added_at.to_i)
        end

        def metadata
          md = super
          md.movie_year = Time.parse(delegate.originally_available_at).year rescue nil

          rating_name = delegate.content_rating.upcase
          rating_value = TivoHMO::API::Metadata::MPAA_RATINGS[rating_name]
          if rating_value
            md.mpaa_rating = {name: rating_name, value: rating_value}
          end

          md
        end

      end

    end
  end
end
