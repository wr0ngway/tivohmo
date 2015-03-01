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
            if super.blank?
              Config.instance.known_config.keys.sort.each do |k|
                add_child(KeyContainer.new(k))
              end
            end
          end

          super
        end

      end

    end
  end
end
