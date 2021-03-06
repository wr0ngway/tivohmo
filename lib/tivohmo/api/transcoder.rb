
module TivoHMO
  module API

    # Transcoder abstraction for reading in the data from an Item and
    # transcoding it into a format suitable for display on a tivo
    module Transcoder
      extend ActiveSupport::Concern
      include GemLogger::LoggerSupport

      # https://code.google.com/p/streambaby/wiki/video_compatibility
      VIDEO_FRAME_RATES = %w[60.00 59.94 50.00 30.00 29.97 25.00 24.00 23.98]
      VIDEO_CODECS = %w[mpeg2video] # h264 only for push?
      VIDEO_WIDTHS = %w[1920 1440 1280 720 704 544 480 352]
      VIDEO_HEIGHTS = %w[1080 720 480 240]

      AUDIO_CODECS = %w[ac3 liba52 mp2]
      AUDIO_SAMPLE_RATES = %w[44100 48000]

      attr_accessor :item

      def initialize(item)
        self.item = item
      end

      def transcode(writeable_io, format)
        raise NotImplementedError
      end

      def transcoder_options(format="video/x-tivo-mpeg")
        raise NotImplementedError
      end
    end

  end
end
