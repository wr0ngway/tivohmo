require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Season, :vcr do

  let(:plex_delegate) {
    section = plex_tv_section
    show = section.all.first
    show.seasons.first
  }

  describe "#initialize" do

    it "should instantiate" do
      season = described_class.new(plex_delegate)
      expect(season).to be_a described_class
      expect(season).to be_a TivoHMO::API::Container
      expect(season.title).to eq(plex_delegate.title)
      expect(season.identifier).to eq(plex_delegate.key)
      expect(season.modified_at).to eq(Time.at(plex_delegate.updated_at.to_i))
      expect(season.created_at).to eq(Time.at(plex_delegate.added_at.to_i))
    end

  end

  describe "#children" do

    it "should memoize" do
      season = described_class.new(plex_delegate)
      expect(season.children.object_id).to eq(season.children.object_id)
    end

    it "should have children" do
      season = described_class.new(plex_delegate)
      expect(season.children).to_not be_empty
      season.children.all? {|c| expect(c).to be_instance_of(TivoHMO::Adapters::Plex::Episode) }
    end

  end
  
end
