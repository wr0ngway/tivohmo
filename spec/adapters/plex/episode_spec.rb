require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Episode do

  let(:plex_delegate) { plex_stub(::Plex::Episode) }

  describe "#initialize" do

    it "should instantiate" do
      episode = described_class.new(plex_delegate)
      expect(episode).to be_a described_class
      expect(episode).to be_a TivoHMO::API::Item
      expect(episode.title).to eq(plex_delegate.title)
      expect(episode.identifier).to eq(plex_delegate.key)
      expect(episode.modified_at).to eq(Time.at(plex_delegate.updated_at))
      expect(episode.created_at).to eq(Time.at(plex_delegate.added_at))
    end

  end

end
