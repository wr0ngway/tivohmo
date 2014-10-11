require_relative "../../spec_helper"
require 'tivohmo/adapters/filesystem'

describe TivoHMO::Adapters::Filesystem::FileItem do


  describe "#initialize" do

    describe "#initialize" do

      it "should fail with non-existant file" do
        expect{described_class.new("not-here")}.to raise_error(ArgumentError, /existing file/)
      end

      it "should fail with dir" do
        expect{described_class.new(File.dirname(__FILE__))}.to raise_error(ArgumentError, /existing file/)
      end

      it "should instantiate" do
        file = __FILE__
        subject = described_class.new(file)
        expect(subject).to be_a described_class
        expect(subject.full_path).to eq File.expand_path(file)
        expect(subject.title).to eq File.basename(file)
        expect(subject.modified_at).to_not be_nil
        expect(subject.created_at).to_not be_nil
      end

    end

  end

end
