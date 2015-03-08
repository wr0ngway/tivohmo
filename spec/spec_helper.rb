
require 'rspec'

RSpec.configure do |config|
end

require 'awesome_print'

require 'timecop'

require 'coveralls'
Coveralls.wear!

require 'tivohmo/logging'
Logging.logger.root.level = :error

require 'tivohmo'
require 'open-uri'

require 'webmock/rspec'
WebMock.disable_net_connect!(allow: 'samples.mplayerhq.hu')

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = File.expand_path('../fixtures/vcr', __FILE__)
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = { :record => :once }
  c.ignore_hosts 'samples.mplayerhq.hu'
  # Uncomment this line to see more information about VCR when running tests
  #c.debug_logger = $stderr
end

def video_fixture(name)
  fixture_names = {
      tiny: 'MPEG4 by philips.mp4',
      with_audio: 'test_qcif_200_aac_64.mp4'
  }

  file_name = fixture_names[name]
  raise ArgumentError, "No fixture for :#{name}" unless file_name

  base_url = 'http://samples.mplayerhq.hu/MPEG-4'
  video_url = "#{base_url}/#{URI.escape(file_name)}"

  cache_dir = '/tmp/video_fixtures'
  video_file = "#{cache_dir}/#{file_name}"

  if ! File.exist?(video_file)
    Logging.logger.root.info "Downloading video fixture #{name} from #{video_url}"
    FileUtils.mkdir_p(cache_dir)
    File.write(video_file, open(video_url).read)
  end

  video_file
end

module TestAPI

  class Application
    include TivoHMO::API::Application
  end

  class Container
    include TivoHMO::API::Container
  end

  class Item
    include TivoHMO::API::Item
    def initialize(file)
      super(file)
      self.file = file
    end
  end

  class Metadata
    include TivoHMO::API::Metadata
  end

  class Transcoder
    include TivoHMO::API::Transcoder
    def transcoder_options; {}; end
    def transcode(io, format); io << item.title_path.upcase; end
  end
end

def make_api_tree(parent, *items)
  parent = TivoHMO::API::Server.new unless parent
  if parent.is_a?(TivoHMO::API::Server)
    parent = parent.add_child(TestAPI::Application.new('a'))
  end

  items.each do |item|
    if item.is_a?(Hash)
      item.each do |name, child_items|
        c = parent.add_child(TestAPI::Container.new(name.to_s))
        make_api_tree(c, *child_items)
      end
    elsif item.is_a?(Enumerable)
      make_api_tree(parent, *item)
    else
      parent.add_child(TestAPI::Item.new(item.to_s))
    end
  end

  parent
end

def mktree(path, items)
  items.each do |item|
    if item.is_a?(Hash)
      item.each do |dir, contents|
        p = "#{path}/#{dir}"
        FileUtils.mkdir p
        mktree(p, contents)
      end
    else
      p = "#{path}/#{item}"
      FileUtils.touch p
    end
  end
end

def with_file_tree(*tree)
  Dir.mktmpdir('tivohmo_test') do |dir|
    mktree(dir, tree)
    yield dir
  end
end

def plex_server
  ::Plex::Server.new('localhost', 32400)
end

def plex_movie_section
  plex_server.library.sections.find {|s| s.type == 'movie' && s.title == 'Test Movies'}
end

def plex_tv_section
  plex_server.library.sections.find {|s| s.type == 'show' && s.title == 'Test TV Shows'}
end

def stub_subtitles(media_path, language_code: 'en', type: :file, format: 'srt')
  require 'iso-639'

  allow(TivoHMO::SubtitlesUtil.instance).to receive(:subtitles_for_media_file).with(media_path) do |path|
    subs = []
    if language_code
      st = TivoHMO::API::Subtitle.new
      st.type = type
      st.format = format
      st.language_code = language_code
      st.language = ISO_639.find_by_code(language_code.downcase).english_name
      st.location = "#{path.chomp(File.extname(path))}.en.srt"
      subs << st
    end
    subs
  end

end