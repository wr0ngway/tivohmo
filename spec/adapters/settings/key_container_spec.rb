require_relative "../../spec_helper"
require 'tivohmo/adapters/settings'

describe TivoHMO::Adapters::Settings::KeyContainer do

  let (:config_key) do
    TivoHMO::Config.instance.known_config.keys.first
  end

  let (:config_spec) do
    TivoHMO::Config.instance.known_config[config_key]
  end

  describe "#initialize" do

    it "should instantiate" do
      cont = described_class.new(config_key)
      expect(cont).to be_a described_class
      expect(cont.children.size).to eq(4)
      expect(cont.children[0]).to be_instance_of(TivoHMO::Adapters::Settings::DisplayItem)
      expect(cont.children[0].title).to eq("Help")
      expect(cont.children[1]).to be_instance_of(TivoHMO::Adapters::Settings::DisplayItem)
      expect(cont.children[1].title).to eq("Default Value: #{config_spec[:default_value]}")
      expect(cont.children[2]).to be_instance_of(TivoHMO::Adapters::Settings::DisplayItem)
      val = !!TivoHMO::Config.instance.get(config_key)
      expect(cont.children[2].title).to eq("Current Value: #{val}")
      expect(cont.children[3]).to be_instance_of(TivoHMO::Adapters::Settings::SetValueItem)
      expect(cont.children[3].title).to eq("Set value to #{!val}")
    end

  end

end
