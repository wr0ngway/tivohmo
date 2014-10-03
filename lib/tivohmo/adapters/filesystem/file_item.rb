#require 'streamio-ffmpeg'

module TivoHMO
  module Adapters
    module Filesystem

      # An Item based on a filesystem file
      class FileItem < TivoHMO::API::Item
        include GemLogger::LoggerSupport

        def initialize(identifier)
          full_path = File.expand_path(identifier)
          raise ArgumentError, "Must provide an existing file" unless File.file?(full_path)

          super(full_path)

          self.title = File.basename(self.identifier)
          self.content_type = "video/x-tivo-mpeg"
          self.source_format = "video/x-tivo-mpeg"
          self.source_size = File.size(self.identifier)
          self.modified_at = File.mtime(self.identifier)
          self.created_at = File.ctime(self.identifier)
        end

      end

    end
  end
end
