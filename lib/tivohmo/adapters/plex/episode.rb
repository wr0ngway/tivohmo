require 'tivohmo/tvdb_helper'

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
          self.created_at = Time.parse(delegate.originally_available_at) rescue nil
          self.created_at ||= Time.at(delegate.added_at.to_i)
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

            md.series_id = lookup_series_id

          rescue => e
            logger.log_exception e, "Failed to read plex metadata for #{self}"
          end

          md
        end

        # groups tv shows under same name if we can extract a seriesId
        def lookup_series_id
          series_id = nil

          guid = delegate.guid
          if guid =~ /thetvdb:\/\/(\d+)/
            # zap2it ids allow tivo to show a relevant thumbnail image for the
            # series in the My Shows UI.
            tvdb_series_id = $1
            begin
              tvdb_series = TVDBHelper.instance.find_by_id(tvdb_series_id)
              series_id = tvdb_series.zap2it_id
              series_id = series_id.sub(/^EP/, 'SH')
              logger.debug "Using zap2it series id: #{series_id}"
            rescue => e
              logger.log_exception e, "Failed to get zap2it series id", level: :warn
            end

            series_id ||= "SH#{tvdb_series_id}"
          end

          series_id
        end

      end

    end
  end
end
