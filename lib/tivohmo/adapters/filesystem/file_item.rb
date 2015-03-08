#require 'streamio-ffmpeg'

module TivoHMO
  module Adapters
    module Filesystem

      # An Item based on a filesystem file
      class FileItem
        include TivoHMO::API::Item
        include GemLogger::LoggerSupport

        def initialize(identifier, subtitle=nil)
          full_path = File.expand_path(identifier)
          raise ArgumentError, "Must provide an existing file" unless File.file?(full_path)

          super(full_path)

          self.file = full_path
          self.subtitle = subtitle
          self.title = File.basename(self.identifier)
          self.title = "[#{subtitle.language_code} #{subtitle.type} sub] #{self.title}" if subtitle
          self.modified_at = File.mtime(self.identifier)
          self.created_at = File.ctime(self.identifier)
        end

      end

    end
  end
end
