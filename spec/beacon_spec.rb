require_relative "spec_helper"

describe TivoHMO::Beacon do


  describe "#initialize" do

    it "should instantiate with defaults" do
      beacon = described_class.new(1234)
      expect(beacon).to be_a described_class
      expect(beacon.instance_variable_get(:@limit)).to eq(-1)
      expect(beacon.instance_variable_get(:@interval)).to eq(60)
      expect(beacon.instance_variable_get(:@services)).to eq(['TiVoMediaServer:1234/http'])
    end

    it "should instantiate with limit" do
      beacon = described_class.new(1234, limit: 5)
      expect(beacon.instance_variable_get(:@limit)).to eq(5)
    end

    it "should instantiate with interval" do
      beacon = described_class.new(1234, interval: 4)
      expect(beacon.instance_variable_get(:@interval)).to eq(4)
    end

  end

  describe "#beacon_data" do

    before(:each) do
      @beacon = described_class.new(1234)
    end

    it "generates beacon packet" do
      data = %W[
          tivoconnect=1
          method=broadcast
          identity={#{@beacon.instance_variable_get(:@uid)}}
          machine=#{Socket.gethostname}
          platform=pc/tivohmo
          services=#{@beacon.instance_variable_get(:@services).join(';')}
          swversion=#{TivoHMO::VERSION}
      ]

      expect(@beacon.beacon_data('broadcast')).to eq(data.join("\n") + "\n")
    end

  end

  describe "#start/stop/join" do

    it "runs for limit times sleeping for interval" do
      beacon = described_class.new(1234, limit: 2, interval: 0.1)
      expect(beacon).to receive(:sleep).with(0.1).twice
      expect(beacon).to receive(:broadcast).twice
      expect(beacon.instance_variable_get(:@running)).to eq(false)
      beacon.start
      expect(beacon.instance_variable_get(:@running)).to eq(true)
      beacon.join
      expect(beacon.instance_variable_get(:@running)).to eq(false)
    end

    it "runs indefinately for -1 limit" do
      beacon = described_class.new(1234, limit: -1, interval: 0.001)
      expect(beacon).to receive(:sleep).with(0.001).at_least(5).times
      expect(beacon).to receive(:broadcast).at_least(5).times
      beacon.start
      sleep(0.1)
      beacon.stop
      beacon.join
    end

  end

  describe "#broadcast" do

    it "sends a packet on the socket" do
      beacon = described_class.new(1234)
      expect(beacon).to receive(:beacon_data).with('broadcast').and_return('packet')
      socket = beacon.instance_variable_get(:@socket)
      expect(socket).to receive(:send).with('packet', 0, '<broadcast>', 2190)
      beacon.broadcast
    end

  end

end
