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

        def initialize(name, description=nil)
          super(name)
          @description = description
        end

        def metadata
          md = super

          if @description.nil?
            md.description = "Nothing to do here, hit back to return"
          else
            md.description = @description + ".  Nothing to do here, hit back to return"
          end

          md
        end

      end

    end
  end
end
