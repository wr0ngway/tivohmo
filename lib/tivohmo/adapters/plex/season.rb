#require 'streamio-ffmpeg'

module TivoHMO
  module Adapters
    module Plex

      # An Item based on a filesystem file
      class Season < TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :delegate

        def initialize(delegate)
          @delegate = delegate

          super(delegate.key)

          self.title = delegate.title
          self.content_type = "x-container/tivo-videos"
#          self.modified_at = Time.at(delegate.updated_at.to_i)
#          self.created_at = Time.at(delegate.added_at.to_i)
        end

        def children
          synchronize do
            if super.blank?
              Array(delegate.episodes).each do |media|
                add_child(Episode.new(media))
              end
            end
          end

          super
        end

      end

    end
  end
end
