require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Movie do

  let(:plex_delegate) { plex_stub(::Plex::Movie,
                                  originally_available_at: "2013-01-02",
                                  content_rating: 'G') }

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

  describe "#metadata" do

    it "should populate metadata" do
      movie = described_class.new(plex_delegate)
      movie.app = TivoHMO::Adapters::Plex::Application.new('localhost')
      md = movie.metadata
      expect(md.movie_year).to eq(2013)
      expect(md.mpaa_rating).to eq({name: 'G', value: 1})
    end

  end

end
