require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Section do

  let(:plex_delegate) { plex_stub(::Plex::Section) }

  describe "#initialize" do

    it "should instantiate" do
      now = Time.now
      Timecop.freeze(now) do
        section = described_class.new(plex_delegate)
        expect(section).to be_a described_class
        expect(section).to be_a TivoHMO::API::Container
        expect(section.title).to eq(plex_delegate.title)
        expect(section.identifier).to eq(plex_delegate.key)
        expect(section.modified_at).to eq(Time.at(plex_delegate.updated_at))
        expect(section.created_at).to eq(now)
      end
    end

  end

  describe "#children" do

    it "should memoize" do
      section = described_class.new(plex_delegate)
      expect(section.children.object_id).to eq(section.children.object_id)
    end

    it "should have category children" do
      section = described_class.new(plex_delegate)
      expect(section.children.size).to eq(11)
      classes = [TivoHMO::Adapters::Plex::Category, TivoHMO::Adapters::Plex::QualifiedCategory]
      expect(section.children.collect(&:class).uniq.sort_by(&:name)).to eq(classes.sort_by(&:name))
    end

  end

end
