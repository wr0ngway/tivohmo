module TivoHMO
  module API

    # Represents a subtitle
    class Subtitle
      include GemLogger::LoggerSupport

      attr_accessor :language, :language_code, :file

    end

  end
end
