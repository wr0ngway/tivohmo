require_relative "spec_helper"
require 'rack/test'
require 'nokogiri'

Sinatra::Base.set :environment, :test

describe TivoHMO::Server do
  include Rack::Test::Methods

  let(:application) do
    a = TestAPI::Application.new('a1')
    a.metadata_class = TestAPI::Metadata
    a.transcoder_class = TestAPI::Transcoder
    a
  end

  let(:server) do
    s = TivoHMO::API::Server.new
    s.add_child(application)
    s
  end

  # for Rack::Test
  let(:app) { TivoHMO::Server.new(server) }

  before(:each) do
    make_api_tree(application, c1: ['i1'])
  end

  let(:container) { server.find('/a1/c1') }
  let(:item) { server.find('/a1/c1/i1') }
  let(:helpers) { (Class.new { include TivoHMO::Server::Helpers }).new }

  describe "helpers" do

    include Rack::Utils

    describe "#item_url" do

      it "uses title_path as url" do
        expect(helpers.item_url(item)).to eq item.title_path
      end

    end

    describe "#container_url" do

      it "generates a url" do
        url = helpers.container_url(container)
        uri = URI(url)
        expect(uri.path).to eq("/TiVoConnect")
        expect(parse_query(uri.query)).to eq('Command' => 'QueryContainer',
                                             'Container' => container.title_path)
      end

    end

    describe "#item_detail_url" do

      it "generates a url" do
        url = helpers.item_detail_url(item)
        uri = URI(url)
        expect(uri.path).to eq("/TiVoConnect")
        expect(parse_query(uri.query)).to eq('Command' => 'TVBusQuery',
                                             'Container' => 'a1',
                                             'File' => 'c1/i1')
      end

    end

    describe "#format_uuid" do

      it "uses crc to format" do
        uuid = SecureRandom.uuid
        expect(helpers.format_uuid(uuid)).to eq(Zlib.crc32(uuid))
      end

    end

    describe "#format_date" do

      it "produces date as hex" do
        date = Time.now
        expect(helpers.format_date(date)).to eq("0x#{date.to_i.to_s(16)}")
      end

    end

    describe "#format_iso_date" do

      it "is empty string for nil" do
        date = nil
        expect(helpers.format_iso_date(date)).to eq("")
      end

      it "is formatted for real date" do
        date = Time.now
        expect(helpers.format_iso_date(date)).to eq(date.utc.strftime("%FT%T.%6N"))
      end

    end

    describe "#format_iso_duration" do

      it "is empty string for nil" do
        expect(helpers.format_iso_duration(nil)).to eq("")
      end

      it "produces iso formatted string" do
        duration = (1 * 86400) + (1 * 3600) + (1 * 60) + 1
        expect(helpers.format_iso_duration(duration)).to eq('P1DT1H1M1S')
      end

    end

    describe "#tivo_header" do

      it "determines pad length" do
        expect(helpers.pad(7, 4)).to eq(1)
      end

      it "tivo_header" do
        expect(helpers).to receive(:builder).
                               with(:item_details, layout: true, locals: {item: item}).
                               and_return("<TvBusMarshalledStruct/>")

        # should not translit for header as HD UI handles more utf8 chars
        expect(helpers).to_not receive(:transliterate)

        expect(helpers.tivo_header(item, 'video/x-tivo-mpeg')).to include('TvBusMarshalledStruct')
      end

    end

    describe "#transliterate" do

      it "generates ascii safe string" do
        expect(helpers.transliterate("\u2019")).to eq("'")
        expect(helpers.transliterate("\u2026")).to eq("...")
      end

    end

  end

  describe "TivoConnect" do

    it "should fail for no command" do
      get '/TiVoConnect'
      expect(last_response.status).to eq(404)
    end

    it "should have a stub response for ResetServer" do
      get '/TiVoConnect?Command=ResetServer'
      expect(last_response.status).to eq(200)
    end

    it "should have a stub response for FlushServer" do
      get '/TiVoConnect?Command=FlushServer'
      expect(last_response.status).to eq(200)
    end

    it "should have a stub response for QueryItem" do
      get '/TiVoConnect?Command=QueryItem'
      expect(last_response.status).to eq(200)
    end

    it "should have a response for QueryServer" do
      get '/TiVoConnect?Command=QueryServer'
      expect(last_response.status).to eq(200)
      doc = Nokogiri::XML(last_response.body)
      name = doc.at_xpath('/TiVoServer/InternalName').content
      expect(name).to eq('TivoHMO')

    end

    describe "QueryFormats" do

      it "should have an error for QueryFormats with video" do
        get '/TiVoConnect?Command=QueryFormats'
        expect(last_response.status).to eq(404)
      end

      it "should have a response for QueryFormats" do
        get '/TiVoConnect?Command=QueryFormats&SourceFormat=video%2Fx-tivo-mpeg'
        expect(last_response.status).to eq(200)
        doc = Nokogiri::XML(last_response.body)
        cts = doc.xpath('/TiVoFormats/Format/ContentType')
        expect(cts.collect(&:content)).to eq(['video/x-tivo-mpeg', 'video/x-tivo-mpeg-ts'])
      end

    end

    describe "TVBusQuery" do

      it "fails if it doesn't have params" do
        get "/TiVoConnect?Command=TVBusQuery"
        expect(last_response.status).to eq(404)
      end

      it "fails if it doesn't exist" do
        get "/TiVoConnect?Command=TVBusQuery&Container=Foo&File=Bar"
        expect(last_response.status).to eq(404)
      end

      it "provides item details" do
        get "/TiVoConnect?Command=TVBusQuery&Container=a1&File=c1/i1"
        expect(last_response.status).to eq(200)
        doc = Nokogiri::XML(last_response.body)
        expect(doc).to_not be_nil
      end

    end

    describe "QueryContainer" do

      it "displays root if it doesn't have params" do
        get "/TiVoConnect?Command=QueryContainer"
        expect(last_response.status).to eq(200)
        doc = Nokogiri::XML(last_response.body)
        title = doc.at_xpath("/TiVoContainer/Details/Title").content
        expect(title).to eq(server.title)
      end

      it "should transliterate" do
        server.title = "\u2026"
        get "/TiVoConnect?Command=QueryContainer"
        expect(last_response.status).to eq(200)
        doc = Nokogiri::XML(last_response.body)
        title = doc.at_xpath("/TiVoContainer/Details/Title").content
        expect(title).to_not eq(server.title)
        expect(title).to eq('...')
      end

      it "uses server as root" do
        get "/TiVoConnect?Command=QueryContainer&Container=/"
        expect(last_response.status).to eq(200)
        doc = Nokogiri::XML(last_response.body)
        title = doc.at_xpath("/TiVoContainer/Details/Title").content
        expect(title).to eq(server.title)
      end

      it "renders a container" do
        container.add_child(TestAPI::Container.new("c2"))

        get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1"
        expect(last_response.status).to eq(200)
        doc = Nokogiri::XML(last_response.body)
        expect(doc.at_xpath("/TiVoContainer/ItemStart").content).to eq("0")
        expect(doc.at_xpath("/TiVoContainer/ItemCount").content).to eq("2")

        expect(doc.at_xpath("/TiVoContainer/Details/TotalItems").content).to eq("2")
        expect(doc.at_xpath("/TiVoContainer/Details/Title").content).to eq(container.title_path)
        expect(doc.at_xpath("/TiVoContainer/Details/ContentType").content).to eq("x-tivo-container/folder")
        expect(doc.at_xpath("/TiVoContainer/Details/SourceFormat").content).to eq("x-tivo-container/folder")
        expect(doc.at_xpath("/TiVoContainer/Details/UniqueId").content).to eq(helpers.format_uuid(container.uuid).to_s)

        expect(doc.xpath("/TiVoContainer/Item").size).to eq (2)

        child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
        expect(child_titles).to match_array(["c2", "i1"])
      end

      it "shows details for child item" do
        get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1"
        expect(last_response.status).to eq(200)
        doc = Nokogiri::XML(last_response.body)

        xml_item = doc.at_xpath("/TiVoContainer/Item")
        expect(xml_item.at_xpath("Details/Title").content).to eq("i1")
        expect(xml_item.at_xpath("Details/ContentType").content).to eq(item.content_type)
        expect(xml_item.at_xpath("Details/SourceFormat").content).to eq(item.source_format)
        expect(xml_item.at_xpath("Details/CaptureDate").content).to eq(helpers.format_date(item.created_at))
        expect(xml_item.at_xpath("Details/UniqueId")).to be_nil
        expect(xml_item.at_xpath("Details/TotalItems")).to be_nil
        expect(xml_item.at_xpath("Details/LastCaptureDate")).to be_nil

        # if metadata present
        expect(xml_item.at_xpath("Details/SourceSize").content).to_not be_nil

        xml_details = xml_item.at_xpath("Links/Content")
        expect(xml_details.at_xpath("Url").content).to eq(helpers.item_url(item))
        expect(xml_details.at_xpath("ContentType").content).to eq(item.content_type)

        expect(xml_item.at_xpath("Links/CustomIcon").content).to_not be_nil

        expect(xml_item.at_xpath("Links/TiVoVideoDetails/Url").content).to eq(helpers.item_detail_url(item))
      end

      it "shows details for child container" do
        c2 = application.add_child(TestAPI::Container.new("c2"))
        c3 = c2.add_child(TestAPI::Container.new("c3"))
        c3 << TestAPI::Item.new('i2')
        c3 << TestAPI::Item.new('i3')

        get "/TiVoConnect?Command=QueryContainer&Container=/a1/c2"
        expect(last_response.status).to eq(200)
        doc = Nokogiri::XML(last_response.body)

        xml_item = doc.at_xpath("/TiVoContainer/Item")
        expect(xml_item.at_xpath("Details/Title").content).to eq("c3")
        expect(xml_item.at_xpath("Details/ContentType").content).to eq(c3.content_type)
        expect(xml_item.at_xpath("Details/SourceFormat").content).to eq(c3.source_format)
        expect(xml_item.at_xpath("Details/UniqueId").content).to eq(helpers.format_uuid(c3.uuid).to_s)
        expect(xml_item.at_xpath("Details/TotalItems").content).to eq("2")
        expect(xml_item.at_xpath("Details/LastCaptureDate").content).to eq(helpers.format_date(c3.created_at))

        xml_details = xml_item.at_xpath("Links/Content")
        expect(xml_details.at_xpath("Url").content).to eq(helpers.container_url(c3))
        expect(xml_details.at_xpath("ContentType").content).to eq("x-tivo-container/folder")

      end

      describe "recursing" do

        before(:each) do
          other_container = container.add_child(TestAPI::Container.new("c2"))
          other_container.add_child(TestAPI::Item.new("i2")) # dupe child
          other_container.add_child(TestAPI::Item.new("i98")) # unique child

          third_container = other_container.add_child(TestAPI::Container.new("c3"))
          other_container.add_child(TestAPI::Item.new("i99")) # unique child
          other_container.add_child(TestAPI::Item.new("i3")) # dupe child

          3.times do |i|
            container.add_child(TestAPI::Item.new("i#{i + 2}"))
          end
        end

        it "recurses all items uniquely depending on force_grouping config" do
          described_class.config_set(:force_grouping, false)
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&Recurse=Yes"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)
          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to eq(["i1", "i2", "i3", "i4", "i98", "i99"])

          described_class.config_set(:force_grouping, true)
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&Recurse=Yes"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)
          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to eq(["i1", "c2", "i2", "i3", "i4"])
        end

      end

      describe "sorting" do

        before(:each) do
          3.times do |i|
            container.add_child(TestAPI::Item.new("i#{i + 2}"))
          end
        end

        it "displays sorted by title" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&SortOrder=Title"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to eq(["i1", "i2", "i3", "i4"])
        end

        it "honors presorted flag" do
          container.presorted = true
          container.children.reverse!
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&SortOrder=Title"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to eq(["i4", "i3", "i2", "i1"])
        end

        it "displays sorted by date" do
          server.find("/a1/c1/i4").created_at = 4.hours.ago
          server.find("/a1/c1/i3").created_at = 3.hours.ago
          server.find("/a1/c1/i2").created_at = 2.hours.ago
          server.find("/a1/c1/i1").created_at = 1.hour.ago
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&SortOrder=CaptureDate"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to eq(["i4", "i3", "i2", "i1"])
        end

        it "honors direction" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&SortOrder=!Title"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to eq(["i4", "i3", "i2", "i1"])
        end

      end

      describe "pagination" do

        before(:each) do
          19.times do |i|
            container.add_child(TestAPI::Item.new("i#{i + 2}"))
          end
        end

        it "displays first page" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          expect(doc.at_xpath("/TiVoContainer/ItemStart").content).to eq("0")
          expect(doc.at_xpath("/TiVoContainer/ItemCount").content).to eq("8")

          expect(doc.at_xpath("/TiVoContainer/Details/TotalItems").content).to eq("20")

          expect(doc.xpath("/TiVoContainer/Item").size).to eq (8)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to match_array(["i1", "i2", "i3", "i4", "i5", "i6", "i7", "i8"])
        end

        it "honors ItemStart" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&ItemStart=3"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          expect(doc.at_xpath("/TiVoContainer/ItemStart").content).to eq("3")
          expect(doc.at_xpath("/TiVoContainer/ItemCount").content).to eq("8")

          expect(doc.at_xpath("/TiVoContainer/Details/TotalItems").content).to eq("20")

          expect(doc.xpath("/TiVoContainer/Item").size).to eq (8)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to match_array(["i4", "i5", "i6", "i7", "i8", "i9", "i10", "i11"])
        end

        it "honors ItemCount" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&ItemCount=3"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          expect(doc.at_xpath("/TiVoContainer/ItemStart").content).to eq("0")
          expect(doc.at_xpath("/TiVoContainer/ItemCount").content).to eq("3")

          expect(doc.at_xpath("/TiVoContainer/Details/TotalItems").content).to eq("20")

          expect(doc.xpath("/TiVoContainer/Item").size).to eq (3)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to match_array(["i1", "i2", "i3"])
        end

        it "honors negative ItemCount (jump to last page)" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&ItemCount=-3"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          expect(doc.at_xpath("/TiVoContainer/ItemStart").content).to eq("17")
          expect(doc.at_xpath("/TiVoContainer/ItemCount").content).to eq("3")

          expect(doc.at_xpath("/TiVoContainer/Details/TotalItems").content).to eq("20")

          expect(doc.xpath("/TiVoContainer/Item").size).to eq (3)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to match_array(["i18", "i19", "i20"])
        end

        it "displays page 2" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&ItemStart=7"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          expect(doc.at_xpath("/TiVoContainer/ItemStart").content).to eq("7")
          expect(doc.at_xpath("/TiVoContainer/ItemCount").content).to eq("8")

          expect(doc.at_xpath("/TiVoContainer/Details/TotalItems").content).to eq("20")

          expect(doc.xpath("/TiVoContainer/Item").size).to eq (8)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to match_array(["i8", "i9", "i10", "i11", "i12", "i13", "i14", "i15"])
        end

        it "displays page using anchors" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&AnchorItem=/a1/c1/i8&AnchorOffset=-1"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          expect(doc.at_xpath("/TiVoContainer/ItemStart").content).to eq("7")
          expect(doc.at_xpath("/TiVoContainer/ItemCount").content).to eq("8")

          expect(doc.at_xpath("/TiVoContainer/Details/TotalItems").content).to eq("20")

          expect(doc.xpath("/TiVoContainer/Item").size).to eq (8)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to match_array(["i8", "i9", "i10", "i11", "i12", "i13", "i14", "i15"])
        end

        it "honors anchor offset when displaying page using anchors" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1/c1&AnchorItem=/a1/c1/i8&AnchorOffset=-8"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          expect(doc.at_xpath("/TiVoContainer/ItemStart").content).to eq("0")
          expect(doc.at_xpath("/TiVoContainer/ItemCount").content).to eq("8")

          expect(doc.at_xpath("/TiVoContainer/Details/TotalItems").content).to eq("20")

          expect(doc.xpath("/TiVoContainer/Item").size).to eq (8)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to match_array(["i1", "i2", "i3", "i4", "i5", "i6", "i7", "i8"])
        end

        it "overrides container with the one from anchor" do
          get "/TiVoConnect?Command=QueryContainer&Container=/a1&AnchorItem=/a1/c1/i8&AnchorOffset=-1"
          expect(last_response.status).to eq(200)
          doc = Nokogiri::XML(last_response.body)

          expect(doc.at_xpath("/TiVoContainer/Details/Title").content).to eq("/a1/c1")

          expect(doc.at_xpath("/TiVoContainer/ItemStart").content).to eq("7")
          expect(doc.at_xpath("/TiVoContainer/ItemCount").content).to eq("8")

          expect(doc.at_xpath("/TiVoContainer/Details/TotalItems").content).to eq("20")

          expect(doc.xpath("/TiVoContainer/Item").size).to eq (8)

          child_titles = doc.xpath("/TiVoContainer/Item/Details/Title").collect(&:content)
          expect(child_titles).to match_array(["i8", "i9", "i10", "i11", "i12", "i13", "i14", "i15"])
        end

      end

    end

  end

  describe "transcode" do

    it "fails if it doesn't exist" do
      get "/this/is/not/here"
      expect(last_response.status).to eq(404)
    end

    it "sends transcoded data" do
      get "/a1/c1/i1?Format=?video/x-tivo-mpeg"
      expect(last_response.status).to eq(206)
      expect(last_response.body).to include("/A1/C1/I1")
    end

  end

end

