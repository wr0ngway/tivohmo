module TivoHMO
  module Adapters
    module Plex

      class Group
        include TivoHMO::API::Container
        include GemLogger::LoggerSupport

        def initialize(ident, title)
          super(ident)

          self.presorted = true
          self.title = title
        end

      end

    end
  end
end
