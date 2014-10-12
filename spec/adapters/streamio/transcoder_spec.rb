require_relative "../../spec_helper"
require 'tivohmo/adapters/streamio'

describe TivoHMO::Adapters::StreamIO::Transcoder do

  let(:item) { TestAPI::Item.new(video_fixture(:tiny)) }

  describe "#initialize" do

    it "should instantiate" do
      trans = described_class.new(item)
      expect(trans).to be_a described_class
      expect(trans.item).to eq(item)
    end

  end

  describe "#transcoder_options" do

    let(:subject) { described_class.new(item) }

    it "returns a hash" do
      opts = subject.transcoder_options
      expect(opts).to be_instance_of(Hash)
    end

  end

  describe "#transcode" do

    let(:subject) { described_class.new(item) }
    let(:destination) { Tempfile.new('streamio_transcode') }

    it "performs a valid transcode" do
      thread = subject.transcode(destination)
      movie = FFMPEG::Movie.new(destination.path)
      expect(movie.valid?).to be(true)
    end

  end

end
