require 'iso-639'
require 'listen'

module TivoHMO

  class SubtitlesUtil
    include GemLogger::LoggerSupport
    include MonitorMixin
    include Singleton

    ALLOWED_SUBTITLE_FORMATS = %w[srt]

    def subtitles_for_media_file(media_path)
      synchronize do
        fq_path = File.realdirpath(media_path)
        base_dir = File.dirname(fq_path)
        base_file = fq_path.chomp(File.extname(fq_path))
        Array(subtitles_for_dir(base_dir)[base_file])
      end
    end

    private

    def refresh_subtitles(dir)
      synchronize do
        @subtitle_files ||= {}
        @subtitle_files[dir] = nil
      end
    end

    def subtitles_for_dir(dir)
      @subtitle_files ||= {}
      @subtitle_files[dir] ||= begin
        subs = {}

        Dir["#{dir}/*"].each do |f|
          # /path/to/movie.<lang_code>.srt
          pieces = f.scan(/(.+)\.(\w+)\.(\w+)$/).flatten
          next if pieces.size != 3

          format = pieces[-1].downcase
          next unless ALLOWED_SUBTITLE_FORMATS.include?(format)

          lang_code = pieces[-2]
          base_path = pieces[-3]

          sub = create_subtitle(f, lang_code, format)
          next unless sub

          subs[base_path] ||= []
          subs[base_path] << sub
        end

        setup_change_listener(dir) unless @subtitle_files.has_key?(dir)

        subs
      end
    end

    def create_subtitle(subtitle_file, lang_code, format)
      iso_entry = ISO_639.find_by_code(lang_code.downcase)
      if iso_entry.nil?
        logger.warn "Subtitle filename has invalid language code: #{subtitle_file}"
        return nil
      end

      st = TivoHMO::API::Subtitle.new
      st.language = iso_entry.english_name
      # use the verbatim code as we could have multiple due to case insensitive fs
      st.language_code = lang_code
      st.format = format
      st.type = :file
      st.location = subtitle_file

      st
    end

    def setup_change_listener(dir)
      logger.debug "Setting up change listener on #{dir}"

      listener = Listen.to(dir) do |modified, added, removed|
        logger.debug "Detected filesystem change (#{added.size}/#{removed.size}) on #{dir}"

        dirs = (added + removed).flatten.collect do |path|
          logger.debug "Inspecting filesystem change: #{path}"

          if ALLOWED_SUBTITLE_FORMATS.include?(File.extname(path)[1..-1])
            File.dirname(path)
          else
            nil
          end
        end
        dirs = dirs.compact.uniq

        dirs.each do |dir|
          logger.debug "Handling filesystem change: #{dir.inspect}"
          refresh_subtitles(dir)
        end

        logger.debug "Completed filesystem refresh on #{dir}"
      end

      listener.start
      listener
    end

  end

end