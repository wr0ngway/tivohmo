require_relative "../spec_helper"
require 'tivohmo/basic_adapter'

describe TivoHMO::BasicAdapter::FileItem do


  describe "#initialize" do

    it "should instantiate" do
      expect(described_class.new(__FILE__)).to be_a described_class
    end

  end

end
