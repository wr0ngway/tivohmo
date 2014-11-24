require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::QualifiedCategory do

  let(:plex_delegate) { plex_stub(::Plex::Section) }


  describe "#initialize" do

    it "should instantiate" do
      now = Time.now
      Timecop.freeze(now) do
        qcat = described_class.new(plex_delegate, :by_year, '2000')
        expect(qcat).to be_a described_class
        expect(qcat).to be_a TivoHMO::API::Container
        expect(qcat.title).to eq("By Year")
        expect(qcat.category_qualifier).to eq('2000')
        expect(qcat.title).to eq("By Year")
        expect(qcat.identifier).to eq(plex_delegate.key)
        expect(qcat.modified_at).to eq(Time.at(plex_delegate.updated_at))
        expect(qcat.created_at).to eq(now)
      end
    end

  end

  describe "#children" do

    it "should memoize" do
      listing = [
          {title: 'Title1', key: 'key1'}
      ]
      allow(plex_delegate).to receive(:years).and_return(listing)
      section = described_class.new(plex_delegate, :by_year, :years)
      expect(section.children.object_id).to eq(section.children.object_id)
    end

    it "should have children" do
      listing = [
          {title: 'Title1', key: 'key1'},
          {title: 'Title2', key: 'key2'}
      ]
      allow(plex_delegate).to receive(:years).and_return(listing)
      section = described_class.new(plex_delegate, :by_year, :years)
      expect(section.children.size).to eq(2)
      expect(section.children[0]).to be_instance_of(TivoHMO::Adapters::Plex::Category)
      expect(section.children[0].category_type).to be(:by_year)
      # reverse order due to sorting by title reversed to work with tivo newest first sorting
      expect(section.children[0].category_value).to eq(listing[1])
      expect(section.children[1].category_value).to eq(listing[0])
    end

  end

end
