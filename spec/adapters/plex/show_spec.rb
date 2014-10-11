require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Show do

  let(:plex_delegate) { plex_stub(::Plex::Show) }

  describe "#initialize" do

    it "should instantiate" do
      show = described_class.new(plex_delegate)
      expect(show).to be_a described_class
      expect(show).to be_a TivoHMO::API::Container
      expect(show.title).to eq(plex_delegate.title)
      expect(show.identifier).to eq(plex_delegate.key)
      expect(show.modified_at).to eq(Time.at(plex_delegate.updated_at))
      expect(show.created_at).to eq(Time.at(plex_delegate.added_at))
    end

  end

end
