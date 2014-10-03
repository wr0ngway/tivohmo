module TivoHMO
  module Adapters
    module Plex

      class Episode
        include TivoHMO::API::Item
        include GemLogger::LoggerSupport

        attr_reader :delegate

        def initialize(delegate)
          @delegate = delegate

          super(delegate.key)

          self.title = delegate.title
          self.content_type = "video/x-tivo-mpeg"
          self.source_format = "video/x-tivo-mpeg"
          self.source_size = delegate.duration.to_i
          self.modified_at = Time.at(delegate.updated_at.to_i)
          self.created_at = Time.at(delegate.added_at.to_i)
        end

      end

    end
  end
end
