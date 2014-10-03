require_relative "../spec_helper"

describe TivoHMO::API::Item do


  describe "#initialize" do

    it "should instantiate" do
      expect(described_class.new('foo')).to be_a described_class
    end

  end

end
