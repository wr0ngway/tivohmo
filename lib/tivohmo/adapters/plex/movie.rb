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

      end

    end
  end
end
