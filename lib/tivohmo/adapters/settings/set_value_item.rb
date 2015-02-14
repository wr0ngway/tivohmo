require 'active_support/core_ext/string/inflections'
require 'listen'

module TivoHMO
  module Adapters
    module Settings

      # An Item for toggling boolean bvalue
      class SetValueItem
        include TivoHMO::API::Item
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :spec

        def initialize(key, new_value)
          super(key)
          @new_value = new_value
          self.title = "Set value to #{new_value}"
        end

      end

    end
  end
end
