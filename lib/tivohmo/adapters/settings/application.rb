module TivoHMO
  module Adapters
    module Settings

      # An Application for live modification of settings
      class Application
        include TivoHMO::API::Application
        include GemLogger::LoggerSupport
        include MonitorMixin


        def initialize(identifier)
          super("Settings")

          self.metadata_class = TivoHMO::Adapters::Settings::Metadata
          self.transcoder_class = TivoHMO::Adapters::Settings::Transcoder
          self.title = self.identifier
          self.presorted = true
        end

        def children
          synchronize do
            super.clear
            Config.instance.known_config.sort.each do |k, v|
              add_child(KeyContainer.new(k, v))
            end
          end

          super
        end

      end

    end
  end
end
