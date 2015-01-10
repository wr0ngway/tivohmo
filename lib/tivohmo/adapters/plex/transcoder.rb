require 'tivohmo/adapters/streamio'

module TivoHMO
  module Adapters
    module Plex

      class Transcoder < TivoHMO::Adapters::StreamIO::Transcoder
        include GemLogger::LoggerSupport

        def initialize(item)
          super(item)
          self.source_filename = CGI.unescape(item.delegate.medias.first.parts.first.file)
        end

        def transcode(writeable_io, format="video/x-tivo-mpeg")
          # TODO: mark as watched in plex
          super
        end

        def transcoder_options(format="video/x-tivo-mpeg")
          opts = super

          if item.respond_to?(:subtitle) && item.subtitle
            logger.debug "Subtitles present for #{item}"
            code = item.subtitle[:language_code].downcase
            sub_file_glob = source_filename.chomp(File.extname(source_filename)) + ".*.srt"

            sub_file = Dir[sub_file_glob].find do |f|
              file_code = f.split('.')[-2].downcase
              file_code == code || file_code.starts_with?(code) || code.starts_with?(file_code)
            end

            if sub_file
              logger.debug "Using subtitles present at: #{sub_file}"
              opts[:custom] ? (opts[:custom] << " ") : (opts[:custom] = "")
              opts[:custom] << "-vf subtitles=\"#{sub_file}\""
            else
              logger.debug "Could not find subtitles for: #{item}"
            end
          end

          opts
        end


      end

    end
  end
end
