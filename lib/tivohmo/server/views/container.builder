xml.TiVoContainer do

  xml.Details do
    xml.Title container.title
    xml.UniqueId format_uuid(container.uuid)
    xml.ContentType container.content_type
    xml.SourceFormat container.source_format
    xml.TotalItems children.size
  end

  # if locals[:show_genres]
  #   xml.Genres do
  #     app.genres.each do |genre|
  #       xml.Genre genre
  #     end
  #   end
  # end

  paginated_children = children[item_start, item_count]
  paginated_children.each do |child|
    if child.is_a?(TivoHMO::API::Container)
      builder :_container, layout: false, locals: { xml: xml, container: child }
    elsif child.is_a?(TivoHMO::API::Item)
      builder :_item, layout: false, locals: { xml: xml, item: child }
    else
      raise "Invalid child, needs to be item or container"
    end
  end

  xml.ItemStart item_start
  xml.ItemCount paginated_children.size

end
