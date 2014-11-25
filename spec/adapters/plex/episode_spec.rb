require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Episode do

  let(:plex_delegate) { plex_stub(::Plex::Episode,
                                  content_rating: 'G',
                                  index: 2,
                                  parent_index: 1,
                                  grandparent_title: 'ShowTitle',
                                  guid: "com.plexapp.agents.thetvdb://269650/1/2?lang=en",
                                  originally_available_at: "2014-06-04") }

  describe "#initialize" do

    it "should instantiate" do
      episode = described_class.new(plex_delegate)
      expect(episode).to be_a described_class
      expect(episode).to be_a TivoHMO::API::Item
      expect(episode.title).to eq(plex_delegate.title)
      expect(episode.identifier).to eq(plex_delegate.key)
      expect(episode.modified_at).to eq(Time.at(plex_delegate.updated_at))
      expect(episode.created_at).to eq(Time.parse(plex_delegate.originally_available_at))
    end

  end

  describe "#metadata" do

    it "should populate metadata" do
      episode = described_class.new(plex_delegate)
      episode.app = TivoHMO::Adapters::Plex::Application.new('localhost')
      md = episode.metadata
      expect(md.original_air_date).to eq(Time.parse(plex_delegate.originally_available_at))
      expect(md.tv_rating).to eq({name: 'G', value: 3})
      expect(md.is_episode).to eq(true)
      expect(md.episode_number).to eq("102")
      expect(md.series_title).to eq("ShowTitle")
      expect(md.episode_title).to eq("102 - Title")
      expect(md.title).to eq("ShowTitle - Title")
      expect(md.series_id).to eq("SH269650")
    end

  end

end
