require_relative "../spec_helper"

describe TivoHMO::API::Transcoder do

  class TestTranscoder
    include TivoHMO::API::Transcoder
  end

  def test_class
    TestTranscoder
  end

  describe "#initialize" do

    it "should initialize" do
      item = double(TivoHMO::API::Item, identifier: 'foo')
      trans = test_class.new(item)
      expect(trans).to be_a(TivoHMO::API::Transcoder)
      expect(trans.item).to eq(item)
      expect(trans.source_filename).to eq('foo')
    end

  end

end
