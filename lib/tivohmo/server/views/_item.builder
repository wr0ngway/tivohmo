xml.Item do

  md = item.metadata

  xml.Details do
    xml.Title item.title
    xml.ContentType item.content_type
    xml.SourceFormat item.source_format

    if md
      xml.SourceSize md.source_size if md.source_size
      xml.Duration md.duration.to_i if md.duration
      xml.Description md.description if md.description

      xml.SourceChannel md.channel[:major_number] if md.channel
      xml.SourceStation md.channel[:callsign] if md.channel

      xml.SeriesId md.series_id
      xml.ShowingBits md.showing_bits if md.showing_bits
      # xml.CopyProtected 'Yes' if md.valid?

      xml.EpisodeTitle md.episode_title if md.is_episode && md.episode_title
      xml.EpisodeNumber md.episode_number if md.episode_number

      xml.ProgramId md.program_id if md.program_id

      xml.TvRating md.tv_rating[:name] if md.tv_rating
      xml.MpaaRating md.mpaa_rating[:name] if md.mpaa_rating
    end

    xml.CaptureDate format_date(item.created_at) if item.created_at

  end

  xml.Links do
    xml.Content do
      xml.ContentType item.content_type
      xml.Url item_url(item)
    end

    xml.CustomIcon do
      xml.ContentType "image/*"
      xml.AcceptsParams "No"
      xml.Url "urn:tivo:image:save-until-i-delete-recording"
    end

    if md
      xml.TiVoVideoDetails do
        xml.ContentType "text/xml"
        xml.AcceptsParams "No"
        xml.Url item_detail_url(item)
      end
    end

  end

end
