module TivoHMO
  module Adapters
    module Plex

      class Application
        include TivoHMO::API::Application
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :server

        def initialize(identifier)
          host, port = identifier.to_s.split(':')
          host ||= 'localhost'
          port ||= 32400
          super("Plex[#{host}:#{port}]")

          self.metadata_class = TivoHMO::Adapters::Plex::Metadata
          self.transcoder_class = TivoHMO::Adapters::Plex::Transcoder
          self.title = self.identifier

          @server = ::Plex::Server.new(host, port)
        end

        def children
          synchronize do
            if super.blank?
              Array(server.library.sections).each do |section|
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