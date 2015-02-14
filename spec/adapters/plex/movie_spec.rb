require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Movie, :vcr do

  let(:plex_delegate) { plex_movie_section.all.first }

  describe "#initialize" do

    it "should instantiate" do
      movie = described_class.new(plex_delegate)
      expect(movie).to be_a described_class
      expect(movie).to be_a TivoHMO::API::Item
      expect(movie.title).to eq(plex_delegate.title)
      expect(movie.identifier).to eq(plex_delegate.key)
      expect(movie.modified_at).to eq(Time.at(plex_delegate.updated_at.to_i))
      expect(movie.created_at).to eq(Time.parse(plex_delegate.originally_available_at))
    end

  end

  describe "#metadata" do

    it "should populate metadata" do
      movie = described_class.new(plex_delegate)
      movie.app = TivoHMO::Adapters::Plex::Application.new('localhost')
      md = movie.metadata
      expect(md.movie_year).to eq(plex_delegate.year.to_i)
      rating = plex_delegate.content_rating.upcase
      expect(md.mpaa_rating).to eq({name: rating,
                                    value: TivoHMO::API::Metadata::MPAA_RATINGS[rating]})

    end

  end

end
