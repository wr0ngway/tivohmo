require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Metadata, :vcr do

  let(:plex_delegate) { plex_movie_section.all.first }

  let(:item) { double('item', delegate: plex_delegate)}

  describe "#initialize" do

    it "should instantiate" do
      md = described_class.new(item)
      expect(md).to be_a described_class
      expect(md).to be_a TivoHMO::API::Metadata
      expect(md.duration).to eq(plex_delegate.duration.to_i / 1000)
      expect(md.description).to eq plex_delegate.summary
      expect(md.star_rating[:name]).to be_nonzero
      expect(md.star_rating[:value]).to be_nonzero
    end

  end

end
