require 'securerandom'

module TivoHMO
  module API

    # Represents the tivo concept of a Container (i.e. a directory that contains
    # files or other containers)
    module Container
      extend ActiveSupport::Concern
      include Node
      include GemLogger::LoggerSupport

      attr_accessor :uuid


      def initialize(identifier)
        super(identifier)
        self.uuid = SecureRandom.uuid
        self.source_format = "x-container/folder"
      end

      def refresh
        self.children = []
      end

    end

  end
end
