require_relative "../../spec_helper"
require 'tivohmo/adapters/settings'

describe TivoHMO::Adapters::Settings::SetValueItem do

  let (:config_key) do
    TivoHMO::Config.instance.known_config.keys.first
  end

  let (:config_spec) do
    TivoHMO::Config.instance.known_config[config_key]
  end

  describe "#initialize" do

    it "should instantiate" do
      new_value = ! TivoHMO::Config.instance.get(config_key)
      item = described_class.new(config_key, new_value)
      expect(item).to be_a described_class
      expect(item.children.size).to eq(0)
      expect(item.title).to eq("Set value to #{new_value}")
    end

    it "should provide metadata description" do
      new_value = ! TivoHMO::Config.instance.get(config_key)
      item = described_class.new(config_key, new_value)
      item.app = TivoHMO::Adapters::Settings::Application.new('settings')

      expect(item.metadata).to_not be_nil
      expect(item.metadata.description).to eq("Value has now been set to #{new_value}, hit back to return")
    end

    it "should not change when reading metadata" do
      new_value = ! TivoHMO::Config.instance.get(config_key)
      item = described_class.new(config_key, new_value)
      item.app = TivoHMO::Adapters::Settings::Application.new('settings')

      expect(item.metadata).to_not be_nil
      expect(TivoHMO::Config.instance.get(config_key)).to_not eq(new_value)
    end

    it "should change when reading metadata" do
      new_value = ! TivoHMO::Config.instance.get(config_key)
      app = TivoHMO::Adapters::Settings::Application.new('settings')
      app.add_child(item = described_class.new(config_key, new_value))

      expect(app.children).to receive(:clear)
      item.metadata.star_rating
      expect(TivoHMO::Config.instance.get(config_key)).to eq(new_value)
    end

  end

end
