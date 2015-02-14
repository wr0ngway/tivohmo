require 'active_support/core_ext/string/inflections'
require 'listen'

module TivoHMO
  module Adapters
    module Settings

      # An Item for displaying a string
      class DisplayItem
        include TivoHMO::API::Item
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :spec, :metadata

        def initialize(name, description)
          super(name)
          @description = description
        end

        def metadata
          md = super
          md.description = @description
          md
        end

      end

    end
  end
end
