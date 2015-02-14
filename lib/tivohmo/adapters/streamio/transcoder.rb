module TivoHMO
  module Adapters
    module StreamIO


      # Transcodes video to tivo format using the streamio gem (ffmpeg)
      class Transcoder
        include TivoHMO::API::Transcoder
        include GemLogger::LoggerSupport

        # TODO: add ability to pass through data (copy codec)
        # for files that are already (partially?) in the right
        # format for tivo.  Check against a mapping of
        # tivo serial->allowed_formats
        # https://code.google.com/p/streambaby/wiki/video_compatibility

        def transcode(writeable_io, format="video/x-tivo-mpeg")
          tmpfile = Tempfile.new('tivohmo_transcode')
          begin
            transcode_thread = run_transcode(tmpfile.path, format)

            # give the transcode thread a chance to start up before we
            # start copying from it.  Not strictly necessary, but makes
            # the log messages show up in the right order
            sleep 0.1

            run_copy(tmpfile.path, writeable_io, transcode_thread)
          ensure
            tmpfile.close
            tmpfile.unlink
          end

          nil
        end

        def transcoder_options(format="video/x-tivo-mpeg")
          opts = {
              video_max_bitrate: 30_000_000,
              buffer_size: 4096,
              audio_bitrate: 448_000,
              format: format,
              custom: []
          }

          opts = select_video_frame_rate(opts)
          opts = select_video_dimensions(opts)
          opts = select_video_codec(opts)
          opts = select_video_bitrate(opts)
          opts = select_audio_codec(opts)
          opts = select_audio_bitrate(opts)
          opts = select_audio_sample_rate(opts)
          opts = select_container(opts)
          opts = select_subtitle(opts)

          custom = opts.delete(:custom)
          opts[:custom] = custom.join(" ") if custom
          opts.delete(:format)

          opts
        end

        protected

        def movie
          @movie ||= FFMPEG::Movie.new(item.file)
        end

        def video_info
          @video_info ||= begin
            info_attrs = %w[
              path duration time bitrate rotation creation_time
              video_stream video_codec video_bitrate colorspace dar
              audio_stream audio_codec audio_bitrate audio_sample_rate
              calculated_aspect_ratio size audio_channels frame_rate container
              resolution width height
            ]
            Hash[info_attrs.collect {|attr| [attr.to_sym, movie.send(attr)] }]
          end
        end

        def select_container(opts)
          if opts[:format] == 'video/x-tivo-mpeg-ts'
            opts[:custom] << "-f mpegts"
          else
            opts[:custom] << "-f vob"
          end
          opts
        end

        def select_audio_sample_rate(opts)
          if video_info[:audio_sample_rate]
            if AUDIO_SAMPLE_RATES.include?(video_info[:audio_sample_rate])
              opts[:audio_sample_rate] = video_info[:audio_sample_rate]
            else
              opts[:audio_sample_rate] = 48000
            end
          end
          opts
        end

        def select_audio_bitrate(opts)
          # transcode assumes unit of Kbit, whilst video_info has unit of bit
          opts[:audio_bitrate] = (opts[:audio_bitrate] / 1000).to_i

          opts
        end

        def select_audio_codec(opts)
          if video_info[:audio_codec]
            if AUDIO_CODECS.any? { |ac| video_info[:audio_codec] =~ /#{ac}/ }
              opts[:audio_codec] = 'copy'
              if video_info[:video_codec] =~ /mpeg2video/
                opts[:custom] << "-copyts"
              end
            else
              opts[:audio_codec] = 'ac3'
            end
          end
          opts
        end

        def select_video_bitrate(opts)
          vbr = video_info[:video_bitrate]
          default_vbr = 16_384_000

          if vbr && vbr > 0
            if vbr >= opts[:video_max_bitrate]
              opts[:video_bitrate] = (opts[:video_max_bitrate] * 0.95).to_i
            elsif vbr > default_vbr
              opts[:video_bitrate] = vbr
            else
              opts[:video_bitrate] = default_vbr
            end
          end

          opts[:video_bitrate] ||= default_vbr

          # transcode assumes unit of Kbit, whilst video_info has unit of bit
          opts[:video_bitrate] = (opts[:video_bitrate] / 1000).to_i
          opts[:video_max_bitrate] = (opts[:video_max_bitrate] / 1000).to_i

          opts
        end

        def select_video_codec(opts)
          if VIDEO_CODECS.any? { |vc| video_info[:video_codec] =~ /#{vc}/ }
            opts[:video_codec] = 'copy'
            if video_info[:video_codec] =~ /h264/
              opts[:custom] << "-bsf h264_mp4toannexb"
            end
          else
            opts[:video_codec] = 'mpeg2video'
            opts[:custom] << "-pix_fmt yuv420p"
          end
          opts
        end

        def select_video_dimensions(opts)
          video_width = video_info[:width].to_i
          VIDEO_WIDTHS.each do |w|
            w = w.to_i
            if video_width >= w
              video_width = w
              opts[:preserve_aspect_ratio] = :width
              break
            end
          end
          video_width = VIDEO_WIDTHS.last.to_i unless video_width

          video_height = video_info[:height].to_i
          VIDEO_WIDTHS.each do |h|
            h = h.to_i
            if video_height >= h
              video_height = h
              opts[:preserve_aspect_ratio] = :height
              break
            end
          end
          video_height = VIDEO_HEIGHTS.last.to_i unless video_height

          opts[:resolution] = "#{video_width}x#{video_height}"
          opts[:preserve_aspect_ratio] ||= :height
          opts
        end

        def select_video_frame_rate(opts)

          frame_rate = video_info[:frame_rate]
          if frame_rate =~ /\A[0-9\.]+\Z/
            frame_rate = frame_rate.to_f
          elsif frame_rate =~ /\A\((\d+)\/(\d+)\)\Z/
            frame_rate = $1.to_f / $2.to_f
          end

          VIDEO_FRAME_RATES.each do |r|
            opts[:frame_rate] = r
            break if frame_rate >= r.to_f
          end

          opts
        end

        def select_subtitle(opts)

          if item.subtitle
            logger.debug "Using subtitles present at: #{item.subtitle.file}"
            opts[:custom] << "-vf subtitles=\"#{item.subtitle.file}\""
          end

          opts
        end

        def run_transcode(output_filename, format)

          logger.info "Movie Info: " +
                          video_info.collect {|k, v| "#{k}=#{v.inspect}"}.join(' ')

          opts = transcoder_options(format)

          logger.info "Transcoding options: " +
                           opts.collect {|k, v| "#{k}='#{v}'"}.join(' ')


          aspect_opt = opts.delete(:preserve_aspect_ratio)
          t_opts = {}
          t_opts[:preserve_aspect_ratio] = aspect_opt if aspect_opt


          transcode_thread = Thread.new do
            begin
              logger.info "Starting transcode of '#{movie.path}' to '#{output_filename}'"
              transcoded_movie = movie.transcode(output_filename, opts, t_opts) do |progress|
                logger.info ("[%3i%%] Transcoding #{File.basename(movie.path)}" % (progress * 100).to_i)
                raise "Halted" if Thread.current[:halt]
              end
              logger.info "Transcoding completed, transcoded file size: #{File.size(output_filename)}"
            rescue => e
              logger.error ("Transcode failed: #{e}")
            end
          end

          return transcode_thread
        end

        # we could avoid this if streamio-ffmpeg had a way to output to an IO, but
        # it only supports file based output for now, so have to manually copy the
        # file's bytes to our output stream
        def run_copy(transcoded_filename, writeable_io, transcode_thread)
          logger.info "Starting stream copy from: #{transcoded_filename}"
          file = File.open(transcoded_filename, 'rb')
          begin
            bytes_copied = 0

            # copying the IO from transcoded file to web output
            # stream is faster than the transcoding, and thus we
            # hit eof before transcode is done.  Therefore we need
            # to keep retrying while the transcode thread is alive,
            # then to avoid a race condition at the end, we keep
            # going till we've copied all the bytes
            while transcode_thread.alive? || bytes_copied < File.size(transcoded_filename)
              # sleep a bit at start of thread so we don't have a
              # wasteful tight loop when transcoding is really slow
              sleep 0.2

              while data = file.read(4096)
                break unless data.size > 0
                writeable_io << data
                bytes_copied += data.size
                end
              end

            logger.info "Stream copy completed, #{bytes_copied} bytes copied"
          rescue => e
            logger.error ("Stream copy failed: #{e}")
            transcode_thread[:halt] = true
          ensure
            file.close
          end
        end

      end

    end
  end
end
