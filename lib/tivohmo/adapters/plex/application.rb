require 'active_support/core_ext/string/inflections'

module TivoHMO
  module Adapters
    module Plex

      # A Container based on a filesystem folder
      class Application < TivoHMO::API::Application
        include GemLogger::LoggerSupport
        include MonitorMixin

        attr_reader :server

        def initialize(identifier)
          host, port = identifier.to_s.split(':')
          host ||= 'localhost'
          port ||= 32400
          super

          self.container_class = TivoHMO::Adapters::Plex::Section
          self.metadata_class = TivoHMO::Adapters::Plex::Metadata
          self.transcoder_class = TivoHMO::Adapters::Plex::Transcoder
          self.content_type = "x-container/tivo-videos"

          @server = ::Plex::Server.new(host, port)
          add_child(Library.new(server.library))
        end

      end

    end
  end
end