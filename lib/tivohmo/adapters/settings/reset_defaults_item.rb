require 'active_support/core_ext/string/inflections'
require 'listen'

module TivoHMO
  module Adapters
    module Settings

      # An Item for toggling boolean bvalue
      class ResetDefaultsItem
        include TivoHMO::API::Item
        include GemLogger::LoggerSupport
        include MonitorMixin

        def initialize()
          super('reset_all')
          self.title = "Reset Defaults"
        end

        def metadata
          md = super

          md.description = "All runtime config has now been reset to defaults, hit back to return"

          md.item_detail_callback = Proc.new do
            logger.info("Resetting defaults")
            Config.instance.known_config.each do |key, spec|
              Config.instance.set(key, spec[:default_value])
            end
            parent.children.clear
          end

          md
        end

      end

    end
  end
end
