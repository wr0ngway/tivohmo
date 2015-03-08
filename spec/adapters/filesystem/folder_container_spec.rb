require_relative "../../spec_helper"
require 'tivohmo/adapters/filesystem'

describe TivoHMO::Adapters::Filesystem::FolderContainer do

  describe "#initialize" do

    it "should fail with non-existant dir" do
      expect{described_class.new("not-here")}.to raise_error(ArgumentError, /existing directory/)
    end

    it "should fail with file" do
      expect{described_class.new(__FILE__)}.to raise_error(ArgumentError, /existing directory/)
    end

    it "should instantiate" do
      with_file_tree(foo: [1]) do |dir|
        subject = described_class.new("#{dir}/foo")
        expect(subject).to be_a described_class
        expect(subject.full_path).to eq "#{dir}/foo"
        expect(subject.title).to eq 'Foo'
        expect(subject.modified_at).to_not be_nil
        expect(subject.created_at).to_not be_nil
        expect(subject.allowed_item_types).to eq %i[file dir]
        expect(subject.allowed_item_extensions).to eq described_class::VIDEO_EXTENSIONS
      end
    end

  end

  describe "#allowed_container?" do

    it "is false when not allowed" do
      with_file_tree(1, foo: []) do |dir|
        subject = described_class.new(dir)
        subject.allowed_item_types = %i[dir]
        expect(subject.send(:allowed_container?, "#{dir}/foo")).to eq(true)
        expect(subject.send(:allowed_container?, "#{dir}/1")).to eq(false)
        expect(subject.send(:allowed_container?, "#{dir}/nothere")).to eq(false)
        subject.allowed_item_types = %i[]
        expect(subject.send(:allowed_container?, "#{dir}/foo")).to eq(false)
      end
    end

  end

  describe "#allowed_item?" do

    it "is false when not allowed" do
      with_file_tree('1.avi', '1.bad', foo: []) do |dir|
        subject = described_class.new(dir)
        subject.allowed_item_types = %i[file]
        subject.allowed_item_extensions = %w[avi]
        expect(subject.send(:allowed_item?, "#{dir}/1.avi")).to eq(true)
        expect(subject.send(:allowed_item?, "#{dir}/1.bad")).to eq(false)
        expect(subject.send(:allowed_item?, "#{dir}/foo")).to eq(false)
        expect(subject.send(:allowed_item?, "#{dir}/nothere")).to eq(false)
        subject.allowed_item_types = %i[]
        expect(subject.send(:allowed_item?, "#{dir}/1.avi")).to eq(false)
      end
    end

  end

  describe "#children" do

    it "contains filesystem children" do
      with_file_tree('1.avi', foo: ['2.avi']) do |dir|
        subject = described_class.new(dir)
        expect(subject.children.collect(&:title)).to match_array ['1.avi', 'Foo']
        expect(subject.find('1.avi')).to be_a(TivoHMO::API::Item)
        expect(subject.find('1.avi')).to be_a(TivoHMO::Adapters::Filesystem::FileItem)
        expect(subject.find('Foo')).to be_a(TivoHMO::API::Container)
        expect(subject.find('Foo')).to be_a(TivoHMO::Adapters::Filesystem::FolderContainer)
      end
    end

    it "memoizes" do
      subject = described_class.new(File.dirname(__FILE__))
      expect(subject.children.object_id).to eq subject.children.object_id
    end

    it "should have children with subtitles" do
      with_file_tree('1.avi', '1.en.srt', '2.avi') do |dir|
        described_class.config_set(:enable_subtitles, true)
        subject = described_class.new(dir)

        expect(subject.children.collect(&:title)).to match_array ['1.avi', '2.avi']

        subgroup = subject.children.find {|c| c.is_a?(TivoHMO::Adapters::Filesystem::Group) }
        expect(subgroup).to_not be_nil
        primary = subgroup.children[0]
        sub = subgroup.children[1]
        expect(primary.title).to_not match(/sub\]/)
        expect(sub.title).to match(primary.title)
        expect(sub.title).to match(/sub\]/)
        expect(sub.subtitle.language).to_not be_nil
        expect(sub.subtitle.language_code).to_not be_nil
        expect(sub.subtitle.location).to_not be_nil

        withoutsub = subject.children.find {|c| ! c.is_a?(TivoHMO::Adapters::Filesystem::Group) }
        expect(withoutsub).to_not be_nil
      end
    end

    it "should allow disabling subtitles" do
      with_file_tree('1.avi', '1.en.srt', '2.avi') do |dir|
        described_class.config_set(:enable_subtitles, false)
        subject = described_class.new(dir)
        withsub = subject.children.find {|c| c.is_a?(TivoHMO::Adapters::Filesystem::Group) }
        expect(withsub).to be_nil
      end
    end

  end

end
