module TivoHMO
  module Adapters
    module Plex

      class Episode
        include TivoHMO::API::Item
        include GemLogger::LoggerSupport

        attr_reader :delegate

        def initialize(delegate)
          # delegate is a Plex::Episode
          @delegate = delegate

          super(delegate.key)

          self.title = delegate.title
          self.modified_at = Time.at(delegate.updated_at.to_i)
          self.created_at = Time.at(delegate.added_at.to_i)
        end

        def metadata
          md = super

          begin

            md.original_air_date = Time.parse(delegate.originally_available_at) rescue nil

            rating_name = delegate.content_rating.upcase
            rating_value = TivoHMO::API::Metadata::TV_RATINGS[rating_name]
            if rating_value
              md.tv_rating = {name: rating_name, value: rating_value}
            end

            md.is_episode = true
            md.episode_number = "%i%02i" % [delegate.parent_index, delegate.index]
            md.series_title = delegate.grandparent_title
            md.episode_title = "%i - %s" % [md.episode_number, title]
            md.title = "%s - %s" % [delegate.grandparent_title, title]

            # group tv shows under same name if we can extract a seriesId
            guid = delegate.guid
            if guid =~ /thetvdb:\/\/(\d+)/
              # TODO: figure out how to get zap2it series IDs into plex
              # If we had zap2it ids in plex metadata and extracted them
              # here, tivo would show a relevant thumbnail image for the
              # series in the My Shows UI.
              md.series_id = "SH#{$1}"
            end

          rescue => e
            logger.log_exception e, "Failed to read plex metadata for #{self}"
          end

          md
        end

      end

    end
  end
end
