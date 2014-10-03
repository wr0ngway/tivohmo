require_relative "../spec_helper"
require 'tivohmo/basic_adapter'

describe TivoHMO::BasicAdapter::FolderContainer do


  describe "#initialize" do

    it "should instantiate" do
      expect(described_class.new('.')).to be_a described_class
    end

  end

end
