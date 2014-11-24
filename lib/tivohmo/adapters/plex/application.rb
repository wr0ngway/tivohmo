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
              sections = Array(server.library.sections)
              # Sort by title descending so that creation times are
              # correct for tivo sort of newest first (Time.now for
              # created_at in Section)
              sections = sections.sort_by{|s| s[:title] }.reverse
              sections.each do |section|
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