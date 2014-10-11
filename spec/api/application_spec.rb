require_relative "../spec_helper"

describe TivoHMO::API::Application do

  def test_class
    TestAPI::Application
  end

  describe "#initialize" do

    it "should initialize" do
      node = test_class.new('a')
      expect(node).to be_a(TivoHMO::API::Container)
      expect(node).to be_a(TivoHMO::API::Node)
      expect(node.identifier).to eq('a')
      expect(node.app).to eq(node)
      expect(node.content_type).to eq("x-container/tivo-videos")
      expect(node.source_format).to eq("x-container/folder")
    end

  end

  describe "#metadata_for" do

    before(:each) do
      @app = test_class.new('a')
      @item = double(TivoHMO::API::Item)
    end

    it "should return nil when no metadata_class" do
      expect(@app.metadata_for(@item)).to eq(nil)
    end

    it "should return an instance of the metadata class when present" do
      o = double()
      c = double(TivoHMO::API::Metadata, :new => o)
      @app.metadata_class = c
      expect(@app.metadata_for(@item)).to eq(o)
    end

  end

  describe "#transcoder_for" do

    before(:each) do
      @app = test_class.new('a')
      @item = double(TivoHMO::API::Item)
    end

    it "should return nil when no transcoder_class" do
      expect(@app.transcoder_for(@item)).to eq(nil)
    end

    it "should return an instance of the transcoder class when present" do
      o = double()
      c = double(TivoHMO::API::Transcoder, :new => o)
      @app.transcoder_class = c
      expect(@app.transcoder_for(@item)).to eq(o)
    end

  end

end
