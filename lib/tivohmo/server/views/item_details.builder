xml.TvBusMarshalledStruct :TvBusEnvelope,
    'xmlns:xs' => "http://www.w3.org/2001/XMLSchema-instance",
    'xmlns:TvBusMarshalledStruct' => "http://tivo.com/developer/xml/idl/TvBusMarshalledStruct",
    'xmlns:TvPgdRecording' => "http://tivo.com/developer/xml/idl/TvPgdRecording",
    'xmlns:TvBusDuration' => "http://tivo.com/developer/xml/idl/TvBusDuration",
    'xmlns:TvPgdShowing' => "http://tivo.com/developer/xml/idl/TvPgdShowing",
    'xmlns:TvDbShowingBit' => "http://tivo.com/developer/xml/idl/TvDbShowingBit",
    'xmlns:TvBusDateTime' => "http://tivo.com/developer/xml/idl/TvBusDateTime",
    'xmlns:TvPgdProgram' => "http://tivo.com/developer/xml/idl/TvPgdProgram",
    'xmlns:TvDbColorCode' => "http://tivo.com/developer/xml/idl/TvDbColorCode",
    'xmlns:TvPgdSeries' => "http://tivo.com/developer/xml/idl/TvPgdSeries",
    'xmlns:TvDbShowType' => "http://tivo.com/developer/xml/idl/TvDbShowType",
    'xmlns:TvPgdChannel' => "http://tivo.com/developer/xml/idl/TvPgdChannel",
    'xmlns:TvDbTvRating' => "http://tivo.com/developer/xml/idl/TvDbTvRating",
    'xmlns:TvDbRecordQuality' => "http://tivo.com/developer/xml/idl/TvDbRecordQuality",
    'xmlns:TvDbBitstreamFormat' => "http://tivo.com/developer/xml/idl/TvDbBitstreamFormat",
    'xs:schemaLocation' => "http://tivo.com/developer/xml/idl/TvBusMarshalledStruct TvBusMarshalledStruct.xsd http://tivo.com/developer/xml/idl/TvPgdRecording TvPgdRecording.xsd http://tivo.com/developer/xml/idl/TvBusDuration TvBusDuration.xsd http://tivo.com/developer/xml/idl/TvPgdShowing TvPgdShowing.xsd http://tivo.com/developer/xml/idl/TvDbShowingBit TvDbShowingBit.xsd http://tivo.com/developer/xml/idl/TvBusDateTime TvBusDateTime.xsd http://tivo.com/developer/xml/idl/TvPgdProgram TvPgdProgram.xsd http://tivo.com/developer/xml/idl/TvDbColorCode TvDbColorCode.xsd http://tivo.com/developer/xml/idl/TvPgdSeries TvPgdSeries.xsd http://tivo.com/developer/xml/idl/TvDbShowType TvDbShowType.xsd http://tivo.com/developer/xml/idl/TvPgdChannel TvPgdChannel.xsd http://tivo.com/developer/xml/idl/TvDbTvRating TvDbTvRating.xsd http://tivo.com/developer/xml/idl/TvDbRecordQuality TvDbRecordQuality.xsd http://tivo.com/developer/xml/idl/TvDbBitstreamFormat TvDbBitstreamFormat.xsd",
     'xs:type' => "TvPgdRecording:TvPgdRecording" do

  md = item.metadata

  xml.recordedDuration format_iso_duration(md.duration)
  xml.vActualShowing md.actual_showing
  xml.vBookmark md.bookmark
  xml.recordingQuality md.recording_quality[:name], :value => md.recording_quality[:value]

  xml.showing do

    xml.showingBits :value => md.showing_bits
    xml.time format_iso_date(md.time)
    xml.duration format_iso_duration(md.duration)
    if md.part_count and md.part_index
      xml.partCount md.part_count
      xml.partIndex md.part_index
    end

    xml.program do

      xml.vActor do
        Array(md.actors).each do |actor|
          xml.element actor
        end
      end

      xml.vAdvisory md.advisory

      xml.vChoreographer do
        Array(md.choreographers).each do |choreographer|
          xml.element choreographer
        end
      end

      xml.colorCode md.color_code.try(:[], :name),
                    :value => md.color_code.try(:[], :value)
      xml.description md.description

      xml.vDirector do
        Array(md.directors).each do |director|
          xml.element director
        end
      end

      xml.episodeNumber md.episode_number if md.episode_number
      xml.episodeTitle md.episode_title if md.is_episode && md.episode_title

      xml.vExecProducer do
        Array(md.executive_producers).each do |executive_producer|
          xml.element executive_producer
        end
      end

      xml.vProgramGenre do
        Array(md.program_genres).each do |program_genre|
          xml.element program_genre
        end
      end

      xml.vGuestStar do
        Array(md.guest_stars).each do |guest_star|
          xml.element guest_star
        end
      end

      xml.vHost do
        Array(md.hosts).each do |host|
          xml.element host
        end
      end

      xml.isEpisode md.is_episode

      if md.movie_year
        xml.movieYear md.movie_year
      else
        xml.originalAirDate format_iso_date(md.original_air_date || md.time)
      end

      if md.mpaa_rating
        xml.mpaaRating md.mpaa_rating[:name], :value => md.mpaa_rating[:value]
      end

      xml.vProducer do
        Array(md.producers).each do |producer|
          xml.element producer
        end
      end

      xml.series do
        xml.isEpisodic md.is_episode
        xml.vSeriesGenre do
          Array(md.series_genres).each do |series_genre|
            xml.element series_genre
          end
        end
        xml.seriesTitle md.series_title
        xml.uniqueId md.series_id if md.series_id
      end

      xml.showType md.show_type.try(:[], :name),
                    :value => md.show_type.try(:[], :value)

      if md.star_rating
        xml.starRating md.star_rating[:name], :value => md.star_rating[:value]
      end

      xml.title md.series_title ? md.series_title : (md.title || item.title)

      xml.vWriter do
        Array(md.writers).each do |writer|
          xml.element writer
        end
      end

      xml.uniqueId md.program_id if md.program_id

    end

    xml.channel do
      xml.displayMajorNumber md.channel.try(:[], :major_number)
      xml.displayMinorNumber md.channel.try(:[], :minor_number)
      xml.callsign md.channel.try(:[], :callsign)
    end

    if md.tv_rating
      xml.tvRating md.tv_rating[:name], :value => md.tv_rating[:value]
    end

  end

  xml.startTime format_iso_date(md.start_time)
  xml.stopTime format_iso_date(md.stop_time)

end
