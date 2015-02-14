module TivoHMO
  module Adapters
    module Settings

      # A Container based on a filesystem folder
      class KeyContainer
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :spec

        def initialize(key, spec)
          super(key)
          @spec = spec
          self.presorted = true
        end

        def children
          synchronize do
            super.clear
            add_child(DisplayItem.new('Description', spec[:description]))
            val = Config.instance.get(identifier)
            add_child(DisplayItem.new("Current Value: #{!!val}", ""))
            add_child(SetValueItem.new(identifier, !val))
          end

          super
        end

      end

    end
  end
end
