#GET /TiVoConnect?Command=QueryFormats&SourceFormat=video%2Fx-tivo-mpeg HTTP/1.1.

xml.TiVoFormats do
  formats.each do |format|
    xml.Format do
      xml.ContentType format
      xml.Description ""
    end
  end
end
