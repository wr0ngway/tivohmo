require_relative "../../spec_helper"
require 'tivohmo/adapters/settings'

describe TivoHMO::Adapters::Settings::Metadata do

  describe "#initialize" do

    it "should instantiate" do
      md = described_class.new(double('item'))
    end

    it "should allow not having a callback" do
      md = described_class.new(double('item'))
      expect(md.item_detail_callback).to be_nil

      md.star_rating
    end

    it "should callback on star_rating" do
      md = described_class.new(double('item'))

      called = 0
      md.item_detail_callback = Proc.new do
        called += 1
      end

      md.star_rating
      expect(called).to eq(1)
    end

  end

end
