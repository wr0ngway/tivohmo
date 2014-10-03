
require 'rspec'
RSpec.configure do |config|
end

# require 'coveralls'
# Coveralls.wear!

require 'tivohmo'
require 'open-uri'

def video_fixture(name)
  fixture_names = {
      tiny: 'MPEG4 by philips.mp4'
  }

  file_name = fixture_names[name]
  raise ArgumentError, "No fixture for :#{name}" unless file_name

  base_url = 'http://samples.mplayerhq.hu/MPEG-4'
  video_url = "#{base_url}/#{CGI.escape(file_name)}"

  cache_dir = '/tmp/video_fixtures'
  video_file = "#{cache_dir}/#{file_name}"

  if ! File.exist?(video_file)
    FileUtils.mkdir_p(cache_dir)
    File.open(video_file, 'wb') {|f| f.write(open(video_url).read) }
  end

  video_file
end
