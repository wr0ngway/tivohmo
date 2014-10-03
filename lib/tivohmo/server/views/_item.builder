xml.Item do

  md = item.metadata

  xml.Details do
    xml.Title item.title
    xml.ContentType item.content_type
    xml.SourceFormat item.source_format
    xml.SourceSize item.source_size if item.source_size
    xml.CaptureDate format_date(item.created_at) if item.created_at

    if md
      xml.Description md.description if md.description
      xml.Duration md.duration if md.duration

      xml.SourceChannel md.channel[:major_number] if md.channel
      xml.SourceStation md.channel[:callsign] if md.channel

      xml.SeriesId md.series_id if md.series_id
      xml.ShowingBits md.showing_bits if md.showing_bits
      # xml.CopyProtected 'Yes' if md.valid?

      xml.EpisodeTitle md.episode_title if md.is_episode && md.episode_title
      xml.EpisodeNumber md.episode_number if md.episode_number

      xml.ProgramId md.program_id if md.program_id

      xml.TvRating md.tv_rating[:name] if md.tv_rating
      xml.MpaaRating md.mpaa_rating[:name] if md.mpaa_rating
    end
  end

  xml.Links do
    xml.Content do
      xml.Url item_url(item)
      xml.ContentType item.content_type
    end

    xml.CustomIcon do
      xml.Url "urn:tivo:image:save-until-i-delete-recording"
      xml.ContentType "image/*"
      xml.AcceptsParams "No"
    end

    if md
      xml.TiVoVideoDetails do
        xml.Url item_detail_url(item)
        xml.ContentType "text/xml"
        xml.AcceptsParams "No"
      end
    end

  end

end
