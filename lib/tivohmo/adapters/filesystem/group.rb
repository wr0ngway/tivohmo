module TivoHMO
  module Adapters
    module Filesystem

      class Group
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport

        def initialize(ident, title)
          super(ident)

          self.presorted = true
          self.title = title
          self.modified_at = File.mtime(self.identifier)
          self.created_at = File.ctime(self.identifier)
        end

      end

    end
  end
end
