require_relative "../spec_helper"

describe TivoHMO::API::Application do


  describe "#initialize" do

    it "should instantiate" do
      expect(described_class.new).to be_a described_class
    end

  end

end
