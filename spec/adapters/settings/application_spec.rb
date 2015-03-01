require_relative "../../spec_helper"
require 'tivohmo/adapters/settings'

describe TivoHMO::Adapters::Settings::Application do


  describe "#initialize" do

    it "should instantiate" do
      app = described_class.new('settings')
      expect(app).to be_a described_class
      expect(app.metadata_class).to eq TivoHMO::Adapters::Settings::Metadata
      expect(app.transcoder_class).to eq TivoHMO::Adapters::Settings::Transcoder
      expect(app.children.size).to eq(TivoHMO::Config.instance.known_config.keys.size)
      app.children.all? do |c|
        expect(c).to be_instance_of(TivoHMO::Adapters::Settings::KeyContainer)
        expect(TivoHMO::Config.instance.known_config[c.identifier]).to_not be_nil
      end
    end

  end

end
