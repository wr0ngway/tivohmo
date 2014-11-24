module TivoHMO
  module Adapters
    module Plex

      class Category
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :delegate
        attr_accessor :category_type, :category_value

        def initialize(delegate, category_type, category_value=nil)
          # delegate is a Plex::Section
          @delegate = delegate

          super(delegate.key)

          self.category_type = category_type
          self.category_value = category_value

          if category_value
            self.title = category_value[:title]
          else
            self.title = category_type.to_s.titleize
          end

          self.modified_at = Time.at(delegate.updated_at.to_i)
          self.created_at = Time.now
        end

        def children
          synchronize do

            delegate.refresh
            new_modified_at = delegate.updated_at.to_i
            if new_modified_at > modified_at.to_i
              logger.info "Plex section was updated, refreshing"
              self.modified_at = Time.at(new_modified_at)
              super.clear
            end

            if super.blank?

              if category_value
                listing = delegate.send(category_type, category_value[:key])
              else
                listing = delegate.send(category_type)
              end

              Array(listing).each do |media|
                if media.is_a?(::Plex::Movie)
                  add_child(Movie.new(media))
                elsif media.is_a?(::Plex::Episode)
                  add_child(Episode.new(media))
                elsif media.is_a?(::Plex::Show)
                  add_child(Show.new(media))
                else
                  logger.error "Unknown type for #{media.class} in #{self.title}"
                end
              end
            end
          end

          super
        end

      end

    end
  end
end
