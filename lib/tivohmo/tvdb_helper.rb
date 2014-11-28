require 'tvdbr'

module TivoHMO

  class TVDBHelper
    include GemLogger::LoggerSupport
    include Singleton

    def initialize
      @client = Tvdbr::Client.new('4A7C459A8771A96D')
      @cache = {}
    end

    def find_by_id(series_id)
      @cache[series_id] ||= @client.find_series_by_id(series_id) rescue nil
    end

  end
end
