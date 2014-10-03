require 'active_support/core_ext/string/inflections'
require 'listen'

module TivoHMO
  module Adapters
    module Plex

      # A Container based on a filesystem folder
      class Library < TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :delegate

        def initialize(delegate)
          # TODO: handle string for section for adding roots from CLI
          @delegate = delegate

          super(delegate.key)

          self.title = "Plex on #{delegate.server.host}"
          self.content_type = "x-container/tivo-videos"
          # self.modified_at = Time.at(delegate.updated_at.to_i)
          # self.created_at = Time.at(delegate.updated_at.to_i)
        end

        def children
          synchronize do
            if super.blank?
              Array(delegate.sections).each do |section|
                add_child(Section.new(section))
              end
            end
          end

          super
        end

      end

    end
  end
end