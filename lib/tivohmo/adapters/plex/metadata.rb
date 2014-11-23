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

            case item
              when Episode
                self.original_air_date = Time.parse(item.delegate.originally_available_at) rescue nil

                rating_name = item.delegate.content_rating.upcase
                rating_value = TV_RATINGS[rating_name]
                if rating_value
                  self.tv_rating = {name: rating_name, value: rating_value}
                end

                self.is_episode = true
                self.episode_number = "%i%02i" % [item.delegate.parent_index, item.delegate.index]
                self.series_title = item.delegate.grandparent_title
                self.episode_title = "%i - %s" % [self.episode_number, item.title]
                self.title = "%s - %s" % [item.delegate.grandparent_title, item.title]

                # group tv shows under same name if we can extract a seriesId
                guid = item.delegate.guid
                if guid =~ /thetvdb:\/\/(\d+)/
                  self.series_id = "SH#{$1}"
                end
              when Movie
                self.movie_year = Time.parse(item.delegate.originally_available_at).year rescue nil

                rating_name = item.delegate.content_rating.upcase
                rating_value = MPAA_RATINGS[rating_name]
                if rating_value
                  self.mpaa_rating = {name: rating_name, value: rating_value}
                end

            end

          rescue => e
            logger.error "Failed to read plex metadata: #{e}"
          end
        end

      end

    end
  end
end
