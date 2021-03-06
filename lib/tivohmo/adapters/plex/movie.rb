module TivoHMO
  module Adapters
    module Plex

      class Movie
        include TivoHMO::API::Item
        include GemLogger::LoggerSupport

        attr_reader :delegate

        def initialize(delegate, subtitle=nil)
          # delegate is a Plex::Movie
          @delegate = delegate

          super(delegate.key)

          self.file = CGI.unescape(delegate.medias.first.parts.first.file)
          self.subtitle = subtitle

          self.title = delegate.title
          self.title = "[#{subtitle.language_code} #{subtitle.type} sub] #{self.title}" if subtitle

          self.modified_at = Time.at(delegate.updated_at.to_i)
          self.created_at = Time.parse(delegate.originally_available_at) rescue nil
          self.created_at ||= Time.at(delegate.added_at.to_i)
        end

        def metadata
          md = super

          begin

            md.movie_year = Time.parse(delegate.originally_available_at).year rescue nil

            rating_name = delegate.content_rating.upcase rescue nil
            rating_value = TivoHMO::API::Metadata::MPAA_RATINGS[rating_name]
            if rating_value
              md.mpaa_rating = {name: rating_name, value: rating_value}
            end

            md.actors = delegate.roles.collect(&:tag) rescue nil
            md.program_genres = delegate.genres.collect(&:tag) rescue nil

            %w[writers directors producers].each do |md_name|
              md.send("#{md_name}=", delegate.send(md_name).collect(&:tag)) rescue nil
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
