require_relative "../spec_helper"

describe TivoHMO::API::Metadata do

  describe "#initialize" do

    it "should instantiate" do
      item = TivoHMO::API::Item.new('foo')
      expect(described_class.new(item)).to be_a described_class
    end

  end

end
