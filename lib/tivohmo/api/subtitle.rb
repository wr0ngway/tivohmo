module TivoHMO
  module API

    # Represents a subtitle
    class Subtitle
      include GemLogger::LoggerSupport

      attr_accessor :language, :language_code, :format, :type, :location

    end

  end
end
