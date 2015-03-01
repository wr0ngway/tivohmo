module TivoHMO
  module Adapters
    module Settings

      # A Container based on a filesystem folder
      class KeyContainer
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

        def initialize(key)
          super(key)
          self.presorted = true
        end

        def children
          synchronize do
            if super.blank?
              spec = Config.instance.known_config[identifier]
              add_child(DisplayItem.new("Help", spec[:description]))
              add_child(DisplayItem.new("Default Value: #{spec[:default_value]}"))
              val = Config.instance.get(identifier)
              add_child(DisplayItem.new("Current Value: #{!!val}"))
              add_child(SetValueItem.new(identifier, !val))
            end
          end

          super
        end

      end

    end
  end
end
