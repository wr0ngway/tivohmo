require_relative "../spec_helper"

describe TivoHMO::API::Container do

  def test_class
    TestAPI::Container
  end

  describe "#initialize" do

    it "should initialize" do
      node = test_class.new('c')
      expect(node).to be_a(TivoHMO::API::Node)
      expect(node.identifier).to eq('c')
      expect(node.uuid).to_not be_nil
      expect(node.content_type).to eq("x-tivo-container/tivo-videos")
      expect(node.source_format).to eq("x-tivo-container/folder")
    end

  end

  describe "#refresh" do

    it "should clear children" do
      node = test_class.new('c')
      node2 = node.add_child(test_class.new('c2'))
      expect(node.children).to eq([node2])
      node.refresh
      expect(node.children).to eq([])
    end

  end

end
