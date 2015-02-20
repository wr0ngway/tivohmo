require 'tivohmo/tvdb_helper'

module TivoHMO
  module Adapters
    module Plex

      class Episode
        include TivoHMO::API::Item
        include GemLogger::LoggerSupport
        include TivoHMO::Config::Mixin

        attr_reader :delegate, :subtitle

        config_register(:group_with_zap2it, true,
                        "Use zap2it ID for grouping episodes (Gives thumbnail in My Shows, but can cause problems)")

        def initialize(delegate, subtitle=nil)
          # delegate is a Plex::Episode
          @delegate = delegate

          super(delegate.key)

          self.file = CGI.unescape(delegate.medias.first.parts.first.file)
          self.subtitle = subtitle

          self.title = delegate.title
          self.title = "[#{subtitle.language_code} sub] #{self.title}" if subtitle

          self.modified_at = Time.at(delegate.updated_at.to_i)
          self.created_at = Time.parse(delegate.originally_available_at) rescue nil
          self.created_at ||= Time.at(delegate.added_at.to_i)
        end

        def metadata
          md = super

          begin

            md.original_air_date = Time.parse(delegate.originally_available_at) rescue nil

            rating_name = delegate.content_rating.upcase rescue nil
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

            md.actors = delegate.roles.collect(&:tag) rescue nil
            md.series_genres = delegate.genres.collect(&:tag) rescue nil

            %w[writers directors producers].each do |md_name|
              md.send("#{md_name}=", delegate.send(md_name).collect(&:tag)) rescue nil
            end

          rescue => e
            logger.log_exception e, "Failed to read plex metadata for #{self}"
          end

          md
        end

        # groups tv shows under same name if we can extract a seriesId
        def lookup_series_id
          series_id = "SH%08i" % delegate.season.show.key.scan(/\d+/).first.to_i

          guid = delegate.guid
          if guid =~ /thetvdb:\/\/(\d+)/
            # zap2it ids allow tivo to show a relevant thumbnail image for the
            # series in the My Shows UI.
            tvdb_series_id = $1

            if config_get(:group_with_zap2it)
              begin
                tvdb_series = TVDBHelper.instance.find_by_id(tvdb_series_id)
                series_id = tvdb_series.zap2it_id
                series_id = series_id.sub(/^EP/, 'SH')
                logger.debug "Using zap2it series id: #{series_id}"
              rescue => e
                logger.log_exception e, "Failed to get zap2it series id", level: :warn
              end
            end

            series_id ||= "SH#{tvdb_series_id}"
          end

          series_id
        end

      end

    end
  end
end
