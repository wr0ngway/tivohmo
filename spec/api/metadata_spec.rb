require_relative "../spec_helper"

describe TivoHMO::API::Metadata do

  class TestMetadata
    include TivoHMO::API::Metadata
  end

  def test_class
    TestMetadata
  end

  describe "#initialize" do

    it "should initialize" do
      item = double(TivoHMO::API::Item)
      md = test_class.new(item)
      expect(md).to be_a(TivoHMO::API::Metadata)
      expect(md.item).to eq(item)
    end

  end

  describe "#estimate_source_size" do

    it "uses transcoder to estimate size" do
      transcoder = double(TivoHMO::API::Transcoder,
                          transcoder_options: {video_bitrate: 1, audio_bitrate: 2})
      item = double(TivoHMO::API::Item, transcoder: transcoder)

      md = test_class.new(item)
      md.duration = 3
      expect(md.estimate_source_size).to eq(1147)
    end

    it "uses defaults if no bitrates in options to estimate size" do
      transcoder = double(TivoHMO::API::Transcoder,
                          transcoder_options: {})
      item = double(TivoHMO::API::Item, transcoder: transcoder)

      md = test_class.new(item)
      md.duration = 3
      expect(md.estimate_source_size).to eq(11646360)
    end

  end

  describe "#source_size" do

    it "uses estimate_source_size" do
      item = double(TivoHMO::API::Item)
      md = test_class.new(item)
      expect(md).to receive(:estimate_source_size).and_return(5)
      expect(md.source_size).to eq(5)
    end

  end

end
