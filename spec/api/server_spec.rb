require_relative "../spec_helper"

describe TivoHMO::API::Server do

  def test_class
    TivoHMO::API::Server
  end

  describe "#initialize" do

    it "should initialize" do
      node = test_class.new
      expect(node).to be_a(TivoHMO::API::Container)
      expect(node).to be_a(TivoHMO::API::Node)
      expect(node.identifier).to eq('TivoHMO Server')
      expect(node.title).to eq(Socket.gethostname.split(".").first)
      expect(node.root).to eq(node)
      expect(node.content_type).to eq("x-container/tivo-server")
      expect(node.source_format).to eq("x-container/folder")
    end

  end

end
