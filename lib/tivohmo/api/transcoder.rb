
module TivoHMO
  module API

    # Transcoder abstraction for reading in the data from an Item and
    # transcoding it into a format suitable for display on a tivo
    class Transcoder
      include GemLogger::LoggerSupport

      attr_accessor :item

      def initialize(item)
        self.item = item
      end

      def transcode(writeable_io)
        raise NotImplementedError
      end

    end

  end
end
