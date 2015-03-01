require_relative "../../spec_helper"
require 'tivohmo/adapters/settings'

describe TivoHMO::Adapters::Settings::DisplayItem do

  describe "#initialize" do

    it "should instantiate" do
      item = described_class.new("Foo")
      expect(item).to be_a described_class
      expect(item.children.size).to eq(0)
      expect(item.title).to eq("Foo")
    end

    it "should provide metadata description" do
      item = described_class.new("Foo")
      item.app = TivoHMO::Adapters::Settings::Application.new('settings')
      expect(item.metadata.description).to eq("Nothing to do here, hit back to return")
    end

    it "should provide extended metadata description" do
      item = described_class.new("Foo", "This is foo")
      item.app = TivoHMO::Adapters::Settings::Application.new('settings')
      expect(item.metadata.description).to eq("This is foo.  Nothing to do here, hit back to return")
    end

  end

end
