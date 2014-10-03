require 'securerandom'

module TivoHMO
  module API

    # Represents the tivo concept of a Container (i.e. a directory that contains
    # files or other containers)
    class Container < Node
      include GemLogger::LoggerSupport

      attr_accessor :uuid


      def initialize(identifier, parent: nil)
        super(identifier, parent: parent)
        self.uuid = SecureRandom.uuid
        self.source_format = "x-container/folder"
      end

      def refresh
        self.children = []
      end

    end

  end
end
