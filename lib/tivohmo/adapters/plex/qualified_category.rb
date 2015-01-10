module TivoHMO
  module Adapters
    module Plex

      class QualifiedCategory
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :delegate
        attr_accessor :category_type, :category_qualifier

        def initialize(delegate, category_type, category_qualifier)
          # delegate is a Plex::Section
          @delegate = delegate

          super(delegate.key)
          self.presorted = true

          self.category_type = category_type
          self.category_qualifier = category_qualifier
          self.title = category_type.to_s.titleize
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
              qualified = Array(delegate.send(category_qualifier))
              # Sort by title descending so that creation times are
              # correct for tivo sort of newest first (Time.now for
              # created_at in Category)
              qualified = qualified.sort_by{|c| c[:title] }.reverse
              qualified.each do |category_value|
                add_child(Category.new(delegate, category_type, category_value))
              end
            end
          end

          super
        end

      end

    end
  end
end
