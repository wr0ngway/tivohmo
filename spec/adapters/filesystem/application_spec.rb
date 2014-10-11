require_relative "../../spec_helper"
require 'tivohmo/adapters/filesystem'

describe TivoHMO::Adapters::Filesystem::Application do


  describe "#initialize" do

    it "should instantiate" do
      app = described_class.new(File.dirname(__FILE__))
      expect(app).to be_a described_class
      expect(app).to be_a TivoHMO::Adapters::Filesystem::FolderContainer
      expect(app.metadata_class).to eq TivoHMO::Adapters::StreamIO::Metadata
      expect(app.transcoder_class).to eq TivoHMO::Adapters::StreamIO::Transcoder
    end

  end

end
