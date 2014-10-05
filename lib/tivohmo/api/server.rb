require 'socket'

module TivoHMO
  module API

    # Represents the tivo concept of a Server (i.e. the root node
    # which contains the top level applications)
    class Server
      include Container
      include GemLogger::LoggerSupport

      def initialize
        super('TivoHMO Server')
        self.root = self
        self.title = Socket.gethostname.split('.').first
        self.content_type = "x-container/tivo-server"
        self.source_format = "x-container/folder"
      end

    end

  end
end

