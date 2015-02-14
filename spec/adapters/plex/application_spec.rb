require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Application, :vcr do


  describe "#initialize" do

    it "should instantiate" do
      app = described_class.new('localhost')
      expect(app).to be_a described_class
      expect(app).to be_a TivoHMO::API::Application
      expect(app).to be_a TivoHMO::API::Container
      expect(app.metadata_class).to eq TivoHMO::Adapters::Plex::Metadata
      expect(app.transcoder_class).to eq TivoHMO::Adapters::Plex::Transcoder
    end

  end

  describe "#children" do

    it "should get children" do
      app = described_class.new('localhost')
      expect(app.children).to_not be_empty
    end

  end

end
