require_relative "../../spec_helper"
require 'tivohmo/adapters/streamio'

describe TivoHMO::Adapters::StreamIO::Metadata do

  let(:item) { TestAPI::Item.new(video_fixture(:tiny)) }

  describe "#initialize" do

    it "should instantiate" do
      md = described_class.new(item)
      expect(md).to be_a described_class
      expect(md.item).to eq(item)
      expect(md.movie).to be_instance_of FFMPEG::Movie
      expect(md.duration).to be(7)
    end

    it "should not fail" do
      orig_appenders = Logging.logger.root.appenders
      Logging.logger.root.appenders = nil
      begin
        expect(FFMPEG::Movie).to receive(:new).and_raise("bad")
        md = described_class.new(item)
        expect(md).to be_a described_class
        expect(md.movie).to be_nil
        expect(md.duration).to eq(0)
      ensure
        Logging.logger.root.appenders = orig_appenders
      end
    end

  end

end
