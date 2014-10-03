require_relative "spec_helper"

describe TivoHMO::Beacon do


  describe "#initialize" do

    it "should instantiate" do
      expect(described_class.new(1234)).to be_a described_class
    end

  end

end
