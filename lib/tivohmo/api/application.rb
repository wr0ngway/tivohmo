require 'securerandom'

module TivoHMO
  module API

    # Represents the tivo concept of a Server (i.e. the root node
    # which contains the top level containers)
    class Application < Container
      include GemLogger::LoggerSupport

      attr_accessor :genres,
                    :tsns,
                    :container_class,
                    :transcoder_class,
                    :metadata_class

      def initialize(identifier)
        super(identifier || 'Application', parent: nil)
        self.title = Socket.gethostname
        self.content_type = "x-container/tivo-server"
        self.genres = []
      end

      def add_container(container_identifier)
        container = container_class.new(container_identifier)
        add_child(container)
      end

      def metadata_for(item)
        metadata_class.new(item) if metadata_class
      end

      def transcoder_for(item)
        transcoder_class.new(item) if transcoder_class
      end

    end

  end
end
