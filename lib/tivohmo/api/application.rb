module TivoHMO
  module API

    # Represents the tivo concept of a Server (i.e. the root node
    # which contains the top level containers).  The identifier
    # passed to the ctor should be a string that makes sense
    # for initializing a subclass of app, e.g. a directory,
    # a hostname:port, etc
    module Application
      extend ActiveSupport::Concern
      include Container
      include GemLogger::LoggerSupport

      attr_accessor :transcoder_class,
                    :metadata_class

      def initialize(identifier)
        super(identifier)
        self.app = self
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
