require_relative "../../spec_helper"
require 'tivohmo/adapters/plex'

describe TivoHMO::Adapters::Plex::Transcoder do


  let(:plex_delegate) { plex_stub(::Plex::Movie,
                                  summary: 'Summary',
                                  duration: 10000,
                                  medias: [double('media',
                                                 parts: [double('part',
                                                                file: '/foo')])])}

  let(:item) { double('item', identifier: plex_delegate.key, delegate: plex_delegate)}

  describe "#initialize" do

    it "should instantiate" do
      trans = described_class.new(item)
      expect(trans).to be_a described_class
      expect(trans).to be_a TivoHMO::API::Transcoder
      expect(trans.source_filename).to eq '/foo'
    end

  end

end
