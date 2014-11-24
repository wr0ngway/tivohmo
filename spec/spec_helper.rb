
require 'rspec'
RSpec.configure do |config|
end

require 'timecop'

require 'coveralls'
Coveralls.wear!

require 'tivohmo/logging'
Logging.logger.root.level = :error

require 'tivohmo'
require 'open-uri'

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
    puts "Downloading video fixture #{name} from #{video_url}"
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

def plex_stub(clazz, method_stubs={})
  default_stubs = {
    key: '/some/key',
    title: 'Title',
    summary: 'Summary',
    duration: 100,
    rating: 1,
    updated_at: Time.now.to_i,
    added_at: Time.now.to_i,
    refresh: nil
  }
  d = double(clazz, default_stubs.merge(method_stubs))

  allow(d).to receive(:is_a?) do |arg|
    arg == clazz
  end

  d
end
