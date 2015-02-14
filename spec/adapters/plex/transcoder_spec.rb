require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Transcoder, :vcr do


  let(:plex_delegate) { plex_movie_section.all.first }

  let(:item) { double('item', identifier: plex_delegate.key, delegate: plex_delegate)}

  describe "#initialize" do

    it "should instantiate" do
      trans = described_class.new(item)
      expect(trans).to be_a described_class
      expect(trans).to be_a TivoHMO::API::Transcoder
    end

  end

end
