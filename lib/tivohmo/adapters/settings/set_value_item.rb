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

        def initialize(key, new_value)
          super(key)
          @new_value = new_value
          self.title = "Set value to #{new_value}"
        end

        def metadata
          md = super

          md.description = "Value has now been set to #{@new_value}, hit back to return"

          md.item_detail_callback = Proc.new do
            logger.info("Setting #{identifier} to: #{@new_value}")
            Config.instance.set(identifier, @new_value)
            parent.children.clear
          end

          md
        end

      end

    end
  end
end
