require 'streamio-ffmpeg'
require_relative 'streamio/transcoder'
require_relative 'streamio/metadata'

module TivoHMO
  module BasicAdapter

    class StreamIO
      include GemLogger::LoggerSupport

      FFMPEG.logger = self.logger
      # FFMPEG.ffmpeg_binary =

    end

  end
end
