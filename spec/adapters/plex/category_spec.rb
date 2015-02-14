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

    it "should memoize" do
      section = described_class.new(plex_delegate, :newest)
      expect(section.children.object_id).to eq(section.children.object_id)
    end

    it "should have children" do
      section = described_class.new(plex_delegate, :newest)

      expect(section.children.size).to_not be(0)

      keys = section.children.collect(&:delegate).collect(&:key)
      expected_keys = plex_delegate.newest.collect(&:key)
      expect(keys).to include(*expected_keys)
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
