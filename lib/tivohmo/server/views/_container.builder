xml.Item do

  xml.Details do
    xml.Title container.title
    xml.ContentType container.content_type
    xml.SourceFormat container.source_format
    xml.UniqueId format_uuid(container.uuid)
    xml.TotalItems container.children.size
    xml.LastCaptureDate format_date(container.created_at) if container.created_at
  end

  xml.Links do
    xml.Content do
      xml.Url container_url(container)
      xml.ContentType container.content_type
    end

    xml.CustomIcon do
      xml.Url "urn:tivo:image:save-until-i-delete-recording"
      xml.ContentType "image/*"
      xml.AcceptsParams "No"
    end
  end

end
