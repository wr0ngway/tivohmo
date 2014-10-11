xml.TiVoContainer do

  xml.Details do
    xml.Title container.title
    xml.ContentType container.content_type
    xml.SourceFormat container.source_format
    xml.TotalItems children.size
  end

  paginated_children = children[item_start, item_count]
  paginated_children.each do |child|
    builder :_container, layout: false, locals: { xml: xml, container: child }
  end

  xml.ItemStart item_start
  xml.ItemCount paginated_children.size

end
