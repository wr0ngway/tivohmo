require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Metadata do

  let(:plex_delegate) { plex_stub(::Plex::Movie,
                                  summary: 'Summary',
                                  duration: 10000,
                                  rating: 10) }

  let(:item) { double('item', delegate: plex_delegate)}

  describe "#initialize" do

    it "should instantiate" do
      md = described_class.new(item)
      expect(md).to be_a described_class
      expect(md).to be_a TivoHMO::API::Metadata
      expect(md.duration).to eq(plex_delegate.duration / 1000)
      expect(md.description).to eq plex_delegate.summary
      expect(md.star_rating).to eq({name: 4, value: 7})
    end

  end

end
