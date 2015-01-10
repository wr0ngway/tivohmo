require 'securerandom'

module TivoHMO
  module API

    # Represents the tivo concept of a Container (i.e. a directory that contains
    # files or other containers)
    module Container
      extend ActiveSupport::Concern
      include Node
      include GemLogger::LoggerSupport

      attr_accessor :uuid, :presorted


      def initialize(identifier)
        super(identifier)
        self.uuid = SecureRandom.uuid
        self.presorted = false

        self.content_type = "x-tivo-container/tivo-videos"
        self.source_format = "x-tivo-container/folder"
      end

      def refresh
        self.children = []
      end

    end

  end
end
