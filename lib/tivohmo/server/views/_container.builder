xml.Item do

  xml.Details do
    xml.Title container.title
    xml.ContentType container.content_type
    xml.SourceFormat container.source_format
    xml.UniqueId format_uuid(container.uuid)
    xml.TotalItems container.child_count
    xml.LastCaptureDate format_date(container.created_at) if container.created_at
  end

  xml.Links do
    xml.Content do
      xml.Url container_url(container)
      xml.ContentType "x-tivo-container/folder"
    end
  end

end
