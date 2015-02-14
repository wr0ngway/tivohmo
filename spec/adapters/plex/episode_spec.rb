require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Episode, :vcr do

  let(:plex_delegate) {
    section = plex_tv_section
    show = section.all.first
    season = show.seasons.first
    season.episodes.first
  }

  describe "#initialize" do

    it "should instantiate" do
      episode = described_class.new(plex_delegate)
      expect(episode).to be_a described_class
      expect(episode).to be_a TivoHMO::API::Item
      expect(episode.title).to eq(plex_delegate.title)
      expect(episode.identifier).to eq(plex_delegate.key)
      expect(episode.modified_at).to eq(Time.at(plex_delegate.updated_at.to_i))
      expect(episode.created_at).to eq(Time.parse(plex_delegate.originally_available_at))
    end

  end

  describe "#metadata" do

    it "should populate metadata" do
      episode = described_class.new(plex_delegate)
      episode.app = TivoHMO::Adapters::Plex::Application.new('localhost')
      md = episode.metadata
      expect(md.original_air_date).to eq(Time.parse(plex_delegate.originally_available_at))
      rating = plex_delegate.content_rating.upcase
      expect(md.tv_rating).to eq({name: rating,
                                  value: TivoHMO::API::Metadata::TV_RATINGS[rating]})
      expect(md.is_episode).to eq(true)
      epnum = "%i%02i" % [plex_delegate.parent_index, plex_delegate.index]
      expect(md.episode_number).to eq(epnum)
      expect(md.series_title).to eq(plex_delegate.grandparent_title)
      expect(md.episode_title).to eq("#{epnum} - #{plex_delegate.title}")
      expect(md.title).to eq("#{plex_delegate.grandparent_title} - #{plex_delegate.title}")
      expect(md.series_id).to match(/SH[0-9]+/)
    end

  end

end
