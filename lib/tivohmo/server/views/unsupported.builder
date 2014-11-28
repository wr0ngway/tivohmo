xml.UnsupportedCommand do
  xml.Query do
    params.each do |key, value|
      xml.param(key: key, value: value)
    end
  end
end
