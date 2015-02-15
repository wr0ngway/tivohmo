require_relative "spec_helper"
require 'tempfile'

describe TivoHMO::Config do

  before(:each) do
    TivoHMO::Config.instance.reset
    FileUtils.rm_f([primary, secondary])
  end

  let(:primary) do
    Tempfile.new('primary').path
  end

  let(:secondary) do
    File.expand_path "~/.#{File.basename primary}"
  end

  describe ".setup" do

    it "looks for primary and secondary" do
      described_class.instance.setup(primary)
      expect(described_class.instance.instance_variable_get(:@primary_file)).to eq(primary)
      expect(described_class.instance.instance_variable_get(:@secondary_file)).to eq(secondary)
      expect(described_class.instance.instance_variable_get(:@primary_data)).to eq({})
      expect(described_class.instance.instance_variable_get(:@secondary_data)).to eq({})
    end

    it "loads in primary and secondary" do
      File.write(primary, {'foo' => 'bar'}.to_yaml)
      File.write(secondary, {'baz' => 'boo'}.to_yaml)
      described_class.instance.setup(primary)
      expect(described_class.instance.instance_variable_get(:@primary_data)).to eq({'foo' => 'bar'})
      expect(described_class.instance.instance_variable_get(:@secondary_data)).to eq({'baz' => 'boo'})
    end

  end

  describe "get" do

    before(:each) do
      File.write(primary, {'p1' => 'p1', 'p2' => 'p2', 'p3' => {'p4' => 'p4', 'p5' => 'p5'}}.to_yaml)
      File.write(secondary, {'s1' => 's1', 'p2' => 's2', 'p3' => {'s4' => 's4', 'p5' => 's5'}}.to_yaml)
      described_class.instance.setup(primary)
    end

    it "returns nil for miss" do
      expect(described_class.instance.get(:nokey)).to be_nil
    end

    it "returns value from primary" do
      expect(described_class.instance.get(:p1)).to eq('p1')
    end

    it "returns value from secondary" do
      expect(described_class.instance.get(:s1)).to eq('s1')
    end

    it "returns override value from secondary" do
      expect(described_class.instance.get(:p2)).to eq('s2')
    end

    it "returns primary deep value" do
      expect(described_class.instance.get([:p3, :p4])).to eq('p4')
    end

    it "returns secondary deep value" do
      expect(described_class.instance.get([:p3, :s4])).to eq('s4')
    end

    it "returns override secondary deep value" do
      expect(described_class.instance.get([:p3, :p5])).to eq('s5')
    end

  end

  describe "set" do

    before(:each) do
      File.write(primary, {'p1' => 'p1', 'p2' => 'p2', 'p3' => {'p4' => 'p4', 'p5' => 'p5'}}.to_yaml)
      File.write(secondary, {'s1' => 's1', 'p2' => 's2', 'p3' => {'s4' => 's4', 'p5' => 's5'}}.to_yaml)
      described_class.instance.setup(primary)
    end

    it "sets a value" do
      described_class.instance.set(:s1, 'set1')
      expect(described_class.instance.get(:s1)).to eq('set1')

      described_class.instance.reset
      described_class.instance.setup(primary)
      expect(described_class.instance.get(:s1)).to eq('set1')
    end

    it "sets a value without saving" do
      described_class.instance.set(:s1, 'set1', false)
      expect(described_class.instance.get(:s1)).to eq('set1')

      described_class.instance.reset
      described_class.instance.setup(primary)
      expect(described_class.instance.get(:s1)).to_not eq('set1')
    end

    it "sets a deep value" do
      described_class.instance.set([:p3, :p5], 'set5')
      expect(described_class.instance.get([:p3, :p5])).to eq('set5')

      described_class.instance.reset
      described_class.instance.setup(primary)
      expect(described_class.instance.get([:p3, :p5])).to eq('set5')
    end

  end

  describe TivoHMO::Config::Mixin do

    class TestMixin
      include TivoHMO::Config::Mixin
    end

    class TestMixin2
      include TivoHMO::Config::Mixin
    end

    before(:each) do
      File.write(primary, {'p1' => 'p1', 'p2' => 'p2', 'p3' => {'p4' => 'p4', 'p5' => 'p5'}}.to_yaml)
      File.write(secondary, {'s1' => 's1', 'p2' => 's2', 'p3' => {'s4' => 's4', 'p5' => 's5'}}.to_yaml)
      TivoHMO::Config.instance.setup(primary)
    end

    describe "config_register" do

      it "allows registering a config once" do
        expect(TivoHMO::Config.instance.known_config[:foo]).to be_nil
        TestMixin.config_register(:foo, 3, "this is foo")
        expect(TivoHMO::Config.instance.known_config[:foo]).to eq({
                                                                      default_value: 3,
                                                                      description: "this is foo",
                                                                      source_path: ["test_mixin"]
                                                         })

        expect {
          TestMixin.config_register(:foo, 3, "this is foo")
        }.to raise_error(ArgumentError, /already registered/)
      end

    end

    describe "config_get" do

      it "allows getting config" do
        expect(TestMixin.config_get(:p1)).to eq('p1')
      end

      it "allows getting registered config default" do
        TestMixin.config_register(:foo, 3, "this is foo")
        expect(TestMixin.config_get(:foo)).to eq(3)
      end

      it "allows getting config cross class" do
        expect(TestMixin2.config_get(:p1)).to eq('p1')
      end

      it "allows getting registered config default cross class" do
        TestMixin.config_register(:foo, 3, "this is foo")
        expect(TestMixin2.config_get(:foo)).to eq(3)
      end

      it "allows independent config cross class" do
        TestMixin.config_register(:foo, 3, "this is foo")
        TivoHMO::Config.instance.set(['test_mixin', 'foo'], 'v1')
        expect(TestMixin.config_get(:foo)).to eq('v1')
        expect(TestMixin2.config_get(:foo)).to eq(3)
      end

    end

    describe "config_set" do

      it "allows setting config" do
        TestMixin.config_set(:p1, 'set1')
        expect(TestMixin.config_get(:p1)).to eq('set1')
      end

      it "allows setting registered config" do
        TestMixin.config_register(:foo, 3, "this is foo")
        TestMixin.config_set(:foo, 'set1')
        expect(TestMixin.config_get(:foo)).to eq('set1')
      end

    end

  end

end
