require_relative "../spec_helper"

describe TivoHMO::API::Item do

  def test_class
    TestAPI::Item
  end

  describe "#initialize" do

    it "should initialize" do
      node = test_class.new('i')
      expect(node).to be_a(TivoHMO::API::Item)
      expect(node).to be_a(TivoHMO::API::Node)
      expect(node.identifier).to eq('i')
      expect(node.title).to eq('i')
      expect(node.file).to eq('i')
      expect(node.subtitle).to be_nil
      expect(node.content_type).to eq("video/x-tivo-mpeg")
      expect(node.source_format).to eq("video/x-tivo-mpeg")
    end

  end

  describe "#metadata" do

    before(:each) do
      @app = double(TivoHMO::API::Application)
      @node = test_class.new('i')
      @node.app = @app
    end

    it "asks app for metadata" do
      expect(@app).to receive(:metadata_for).with(@node)
      @node.metadata
    end

  end

  describe "#transcoder" do

    before(:each) do
      @app = double(TivoHMO::API::Application)
      @node = test_class.new('i')
      @node.app = @app
    end

    it "asks app for transcoder" do
      expect(@app).to receive(:transcoder_for).with(@node)
      @node.transcoder
    end

  end

end
