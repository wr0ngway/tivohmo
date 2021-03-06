require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Category, :vcr do

  let(:plex_delegate) { plex_movie_section }

  describe "#initialize" do

    it "should instantiate" do
      now = Time.now
      Timecop.freeze(now) do
        category = described_class.new(plex_delegate, :newest)
        expect(category).to be_a described_class
        expect(category).to be_a TivoHMO::API::Container
        expect(category.category_type).to eq(:newest)
        expect(category.category_value).to be_nil
        expect(category.presorted).to eq(false)
        expect(category.title).to eq('Newest')
        expect(category.identifier).to eq(plex_delegate.key)
        expect(category.modified_at).to eq(Time.at(plex_delegate.updated_at.to_i))
        expect(category.created_at).to eq(now)
      end

    end

    it "should use_category_value for title if present" do
      cval = {title: 'MyTitle', key: '/plex/key'}
      category = described_class.new(plex_delegate, :by_year, cval)
      expect(category.category_type).to eq(:by_year)
      expect(category.category_value).to eq(cval)
      expect(category.title).to eq('MyTitle')
    end

    it "should set presorted if present" do
      cval = {title: 'MyTitle', key: '/plex/key'}
      category = described_class.new(plex_delegate, :by_year, nil, true)
      expect(category.presorted).to eq(true)
    end

  end

  describe "#children" do

    before(:each) do
      if ENV['CI']
        stub_subtitles("/Users/mconway/Movies/TivoHMOTest/Movies/3 Idiots (2009).avi")
        stub_subtitles("/Users/mconway/Movies/TivoHMOTest/Movies/Wyrmwood (2014).avi", language_code: nil)
        stub_subtitles("/Users/mconway/Movies/TivoHMOTest/Movies/Rurouni Kenshin Kyoto Inferno (2014).mkv", language_code: nil)
      end
    end

    it "should memoize" do
      section = described_class.new(plex_delegate, :newest)
      expect(section.children.object_id).to eq(section.children.object_id)
    end

    it "should have children" do
      section = described_class.new(plex_delegate, :newest)

      expect(section.children.size).to_not be(0)

      titles = section.children.collect(&:title)
      expected_titles = plex_delegate.newest.collect(&:title)
      expect(titles).to include(*expected_titles)
    end

    it "should display non-zero child_count once children fetched" do
      section = described_class.new(plex_delegate, :newest)

      expect(section.child_count).to be(0)
      section.children
      expect(section.child_count).to_not be(0)
      expect(section.child_count).to eq(section.children.size)
    end

    it "should have children with subtitles" do
      described_class.config_set(:enable_subtitles, true)
      section = described_class.new(plex_delegate, :newest)

      subgroup = section.children.find {|c| c.is_a?(TivoHMO::Adapters::Plex::Group) }
      expect(subgroup).to_not be_nil
      primary = subgroup.children[0]
      sub = subgroup.children[1]
      expect(primary.title).to_not match(/sub\]/)
      expect(sub.title).to match(primary.title)
      expect(sub.title).to match(/sub\]/)
      expect(sub.subtitle.language).to_not be_nil
      expect(sub.subtitle.language_code).to_not be_nil
      expect(sub.subtitle.location).to_not be_nil

      withoutsub = section.children.find {|c| ! c.is_a?(TivoHMO::Adapters::Plex::Group) }
      expect(withoutsub).to_not be_nil
    end

    it "should have children with embedded subtitles" do
      described_class.config_set(:enable_subtitles, true)
      section = described_class.new(plex_delegate, :newest)

      subgroup = section.children.find {|c|
        c.is_a?(TivoHMO::Adapters::Plex::Group) &&
            c.children.any? {|m| m.subtitle && m.subtitle.type == :embedded }
      }
      expect(subgroup).to_not be_nil
      primary = subgroup.children[0]
      sub = subgroup.children[1]
      expect(primary.title).to_not match(/sub\]/)
      expect(sub.title).to match(primary.title)
      expect(sub.title).to match(/sub\]/)
      expect(sub.subtitle.language).to_not be_nil
      expect(sub.subtitle.language_code).to_not be_nil
      expect(sub.subtitle.location).to eq(0)
    end

    it "should allow disabling subtitles" do
      section = described_class.new(plex_delegate, :newest)
      described_class.config_set(:enable_subtitles, false)
      withsub = section.children.find {|c| c.is_a?(TivoHMO::Adapters::Plex::Group) }
      expect(withsub).to be_nil
    end

    it "should refresh children when config changes" do
      described_class.config_set(:enable_subtitles, false)
      section = described_class.new(plex_delegate, :newest)

      withsub = section.children.select {|c| c.is_a?(TivoHMO::Adapters::Plex::Group) }
      withoutsub = section.children.select {|c| ! c.is_a?(TivoHMO::Adapters::Plex::Group) }
      expect(withsub).to be_empty
      expect(withoutsub).to_not be_empty

      described_class.config_set(:enable_subtitles, true)

      withsub = section.children.select {|c| c.is_a?(TivoHMO::Adapters::Plex::Group) }
      withoutsub = section.children.select {|c| ! c.is_a?(TivoHMO::Adapters::Plex::Group) }
      expect(withsub).to_not be_empty
      expect(withoutsub).to_not be_empty
    end


    it "should use category_value for children" do
      cval = plex_delegate.years.first
      section = described_class.new(plex_delegate, :by_year, cval)

      expect(section.children.size).to_not be(0)

      keys = section.children.collect(&:delegate).collect(&:key)
      expected_keys = plex_delegate.by_year(cval[:key]).collect(&:key)
      expect(keys).to include(*expected_keys)
    end

  end

end
