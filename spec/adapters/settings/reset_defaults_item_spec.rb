require_relative "../../spec_helper"
require 'tivohmo/adapters/settings'

describe TivoHMO::Adapters::Settings::ResetDefaultsItem do

  let (:config_key) do
    TivoHMO::Config.instance.known_config.keys.first
  end

  let (:config_spec) do
    TivoHMO::Config.instance.known_config[config_key]
  end

  describe "#initialize" do

    it "should instantiate" do
      item = described_class.new
      expect(item).to be_a described_class
      expect(item.children.size).to eq(0)
      expect(item.title).to eq("Reset Defaults")
    end

    it "should provide metadata description" do
      new_value = ! TivoHMO::Config.instance.get(config_key)
      item = described_class.new
      item.app = TivoHMO::Adapters::Settings::Application.new('settings')

      expect(item.metadata).to_not be_nil
      expect(item.metadata.description).to eq("All runtime config has now been reset to defaults, hit back to return")
    end

    it "should not change when reading metadata" do
      expect(TivoHMO::Config.instance).to receive(:set).never
      item = described_class.new
      item.app = TivoHMO::Adapters::Settings::Application.new('settings')

      expect(item.metadata).to_not be_nil
    end

    it "should change when reading metadata" do
      app = TivoHMO::Adapters::Settings::Application.new('settings')
      app.add_child(item = described_class.new)

      TivoHMO::Config.instance.known_config.each do |key, spec|
        expect(TivoHMO::Config.instance).to receive(:set).with(key, spec[:default_value])
      end
      expect(app.children).to receive(:clear)

      item.metadata.star_rating
    end

  end

end
