require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Show, :vcr do

  let(:plex_delegate) { plex_tv_section.all.first }

  describe "#initialize" do

    it "should instantiate" do
      show = described_class.new(plex_delegate)
      expect(show).to be_a described_class
      expect(show).to be_a TivoHMO::API::Container
      expect(show.title).to eq(plex_delegate.title)
      expect(show.identifier).to eq(plex_delegate.key)
      expect(show.modified_at).to eq(Time.at(plex_delegate.updated_at.to_i))
      expect(show.created_at).to eq(Time.at(plex_delegate.added_at.to_i))
    end

  end

  describe "#children" do

    it "should memoize" do
      show = described_class.new(plex_delegate)
      expect(show.children.object_id).to eq(show.children.object_id)
    end

    it "should have children" do
      show = described_class.new(plex_delegate)
      expect(show.children).to_not be_empty
      show.children.all? {|c| expect(c).to be_instance_of(TivoHMO::Adapters::Plex::Season) }
    end

  end

end
