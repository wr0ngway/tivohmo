require_relative "../../spec_helper"
require 'tivohmo/adapters/filesystem'

describe TivoHMO::Adapters::Filesystem::Application do


  describe "#initialize" do

    it "should instantiate" do
      app = described_class.new(File.dirname(__FILE__))
      expect(app).to be_a described_class
      expect(app).to be_a TivoHMO::Adapters::Filesystem::FolderContainer
      expect(app.metadata_class).to eq TivoHMO::Adapters::StreamIO::Metadata
      expect(app.transcoder_class).to eq TivoHMO::Adapters::StreamIO::Transcoder
    end

  end

  describe "#children" do

    it "watches for filesystem addition in self" do
      with_file_tree('1.avi', foo: ['2.avi']) do |dir|
        subject = described_class.new(dir)
        expect(subject.children.collect(&:title)).to match_array ['1.avi', 'Foo']
        FileUtils.touch "#{dir}/3.avi"
        sleep 0.5
        expect(subject.children.collect(&:title)).to match_array ['3.avi','1.avi', 'Foo']
      end
    end

    it "watches for filesystem addition in children" do
      with_file_tree('1.avi', foo: ['2.avi']) do |dir|
        subject = described_class.new(dir)
        expect(subject.children.collect(&:title)).to match_array ['1.avi', 'Foo']
        FileUtils.touch "#{dir}/foo/3.avi"
        sleep 0.5
        expect(subject.find("Foo").children.collect(&:title)).to match_array ['3.avi','2.avi']
      end
    end

    it "watches for filesystem removal in self" do
      with_file_tree('1.avi', foo: ['2.avi']) do |dir|
        subject = described_class.new(dir)
        expect(subject.children.collect(&:title)).to match_array ['1.avi', 'Foo']
        FileUtils.rm "#{dir}/1.avi"
        sleep 0.5
        expect(subject.children.collect(&:title)).to match_array ['Foo']
      end
    end

    it "watches for filesystem removal in children" do
      with_file_tree('1.avi', foo: ['2.avi']) do |dir|
        subject = described_class.new(dir)
        expect(subject.children.collect(&:title)).to match_array ['1.avi', 'Foo']
        FileUtils.rm "#{dir}/foo/2.avi"
        sleep 0.5
        expect(subject.find("Foo").children.collect(&:title)).to match_array []
      end
    end

    it "watches for filesystem mod in self" do
      with_file_tree('1.avi', foo: ['2.avi']) do |dir|
        subject = described_class.new(dir)
        orig = subject.find('1.avi')
        sleep 1
        FileUtils.touch "#{dir}/1.avi"
        sleep 0.5
        expect(subject.find('1.avi')).to_not eq(orig)
      end
    end

    it "watches for filesystem mod in children" do
      with_file_tree('1.avi', foo: ['2.avi']) do |dir|
        subject = described_class.new(dir)
        orig = subject.find('Foo/2.avi')
        sleep 1
        FileUtils.touch "#{dir}/foo/2.avi"
        sleep 0.5
        expect(subject.find('Foo/2.avi')).to_not eq(orig)
      end
    end

  end

end
