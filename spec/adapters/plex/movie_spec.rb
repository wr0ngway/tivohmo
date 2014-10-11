require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Movie do

  let(:plex_delegate) { plex_stub(::Plex::Movie) }

  describe "#initialize" do

    it "should instantiate" do
      movie = described_class.new(plex_delegate)
      expect(movie).to be_a described_class
      expect(movie).to be_a TivoHMO::API::Item
      expect(movie.title).to eq(plex_delegate.title)
      expect(movie.identifier).to eq(plex_delegate.key)
      expect(movie.modified_at).to eq(Time.at(plex_delegate.updated_at))
      expect(movie.created_at).to eq(Time.at(plex_delegate.added_at))
    end

  end

end
