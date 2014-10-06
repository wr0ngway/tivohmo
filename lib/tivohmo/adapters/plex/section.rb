module TivoHMO
  module Adapters
    module Plex

      class Section
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :delegate

        def initialize(delegate)
          # delegate is a Plex::Section
          @delegate = delegate

          super(delegate.key)

          self.title = delegate.title
          self.modified_at = Time.at(delegate.updated_at.to_i)
          self.created_at = Time.at(delegate.updated_at.to_i)
        end

        def children
          synchronize do
            if super.blank?
              add_child(Category.new(delegate, :recently_added))
              add_child(Category.new(delegate, :unwatched))
              add_child(Category.new(delegate, :newest))
              add_child(Category.new(delegate, :on_deck))
              add_child(Category.new(delegate, :recently_viewed))
              add_child(Category.new(delegate, :all))
              add_child(QualifiedCategory.new(delegate, :by_genre, :genres))
              add_child(QualifiedCategory.new(delegate, :by_year, :years))
              add_child(QualifiedCategory.new(delegate, :by_first_character, :first_characters))
              add_child(QualifiedCategory.new(delegate, :by_collection, :collections))
              add_child(QualifiedCategory.new(delegate, :by_folder, :folders))
              add_child(QualifiedCategory.new(delegate, :by_content_rating, :content_ratings))
            end
          end

          super
        end

      end

    end
  end
end