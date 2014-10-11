require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Season do

  let(:plex_delegate) { plex_stub(::Plex::Season) }

  describe "#initialize" do

    it "should instantiate" do
      season = described_class.new(plex_delegate)
      expect(season).to be_a described_class
      expect(season).to be_a TivoHMO::API::Container
      expect(season.title).to eq(plex_delegate.title)
      expect(season.identifier).to eq(plex_delegate.key)
      # expect(app.modified_at).to eq(Time.at(plex_delegate.updated_at))
      # expect(app.created_at).to eq(Time.at(plex_delegate.added_at))
    end

  end

end
