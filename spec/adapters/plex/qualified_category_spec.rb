require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::QualifiedCategory, :vcr do

  let(:plex_delegate) { plex_movie_section }


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
        expect(qcat.modified_at).to eq(Time.at(plex_delegate.updated_at.to_i))
        expect(qcat.created_at).to eq(now)
      end
    end

  end

  describe "#children" do

    it "should memoize" do
      section = described_class.new(plex_delegate, :by_year, :years)
      expect(section.children.object_id).to eq(section.children.object_id)
    end

    it "should have children" do
      section = described_class.new(plex_delegate, :by_year, :years)
      expect(section.children).to_not be_empty
      section.children.all? {|c| expect(c).to be_instance_of(TivoHMO::Adapters::Plex::Category) }
      section.children.all? {|c| expect(c.category_type).to be(:by_year) }
      # reverse order due to sorting by title reversed to work with tivo newest first sorting
      expect(section.children[1].category_value[:key]).to be > section.children[0].category_value[:key]
    end

  end

end
