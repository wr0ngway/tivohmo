module TivoHMO
  module API

    # Represents the tivo concept of an Item (i.e. a file that can be
    # displayed), and is always a leaf node in the tree.
    class Item < Node
      include GemLogger::LoggerSupport

      attr_accessor :source_size

      def metadata
        @metadata ||= app.metadata_for(self)
      end

      def transcoder
        @transcoder ||= app.transcoder_for(self)
      end

      def to_s
        "<#{self.class.name}: #{self.identifier}>"
      end

    end

  end
end
