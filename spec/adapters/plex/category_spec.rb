require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Category do

  let(:plex_delegate) { plex_stub(::Plex::Section) }

  describe "#initialize" do

    it "should instantiate" do
      category = described_class.new(plex_delegate, :newest)
      expect(category).to be_a described_class
      expect(category).to be_a TivoHMO::API::Container
      expect(category.category_type).to eq(:newest)
      expect(category.category_value).to be_nil
      expect(category.title).to eq('Newest')
      expect(category.identifier).to eq(plex_delegate.key)
      expect(category.modified_at).to eq(Time.at(plex_delegate.updated_at))
      expect(category.created_at).to eq(Time.at(plex_delegate.added_at))
    end

    it "should use_category_value for title if present" do
      cval = {title: 'MyTitle', key: '/plex/key'}
      category = described_class.new(plex_delegate, :by_year, cval)
      expect(category.category_type).to eq(:by_year)
      expect(category.category_value).to eq(cval)
      expect(category.title).to eq('MyTitle')
    end

  end

  describe "#children" do

    it "should memoize" do
      listing = [plex_stub(::Plex::Movie)]
      allow(plex_delegate).to receive(:newest).and_return(listing)
      section = described_class.new(plex_delegate, :newest)
      expect(section.children.object_id).to eq(section.children.object_id)
    end

    it "should have children" do
      listing = [
          plex_stub(::Plex::Movie),
          plex_stub(::Plex::Episode),
          plex_stub(::Plex::Show)
      ]
      allow(plex_delegate).to receive(:newest).and_return(listing)
      section = described_class.new(plex_delegate, :newest)
      expect(section.children.size).to eq(3)
    end

    it "should use category_value for children" do
      listing = [
          plex_stub(::Plex::Movie),
          plex_stub(::Plex::Episode),
          plex_stub(::Plex::Show)
      ]
      cval = {title: 'Title', key: 'key'}
      allow(plex_delegate).to receive(:by_year).with('key').and_return(listing)
      section = described_class.new(plex_delegate, :by_year, cval)
      expect(section.children.size).to eq(3)
    end

  end

end
