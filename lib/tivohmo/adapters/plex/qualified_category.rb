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

        alias_method :super_children, :children

        def child_count
          super_children.size
        end

        def children
          synchronize do

            # updated_at doesn't get updated for automatic updates, only
            # for updating from within plex media server web ui
            section_id = delegate.key.split('/').last
            new_delegate = delegate.library.section!(section_id)
            new_modified_at = new_delegate.updated_at.to_i
            if new_modified_at > modified_at.to_i
              logger.info "Plex section was updated, refreshing"
              @delegate = new_delegate
              self.modified_at = Time.at(new_modified_at)
              super.clear
            end

            if super.blank?
              qualified = Array(delegate.send(category_qualifier))
              # Sort by title descending so that creation times are
              # correct for tivo sort of newest first (Time.now for
              # created_at in Category)
              qualified = qualified.sort_by{|c| c[:title] }
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
