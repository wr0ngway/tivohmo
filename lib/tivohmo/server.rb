require 'builder'
require 'sinatra/base'
require 'active_support/core_ext/string'
require 'zlib'
require 'time'
require 'unidecoder'

module TivoHMO

  # The http server for serving the Application/Container/Item tree,
  # including an endpoint for transcoding video from the Item to the
  # tivo format
  class Server < Sinatra::Base
    include GemLogger::LoggerSupport
    include TivoHMO::Config::Mixin

    config_register(:force_grouping, true,
                    "Force groups/folders regardless of parameters supplied by the tivo request")

    disable :logging
    set :root, File.expand_path("../server", __FILE__)
    set :reload_templates, true
    set :builder, :content_type => 'text/xml'

    before do
      logger.info "Request from #{request.ip} \"#{request.request_method} #{request.url}\""
      logger.debug "Headers: #{headers.inspect}"
    end

    after do
      if ! response.body.is_a?(Sinatra::Helpers::Stream)
        # Try and reduce invalid chars in browse UI (SD UI) by
        # transliterating from full utf-8 to ascii equivalents
        # The full utf-8 is still provided in tivo_header for
        # display by the HD UI in My Shows
        response.body = response.body.collect{|b| transliterate(b) }
      end
    end

    after do
      logger.info "Response to #{request.ip} for \"#{request.request_method} #{request.url}\" [#{response.status}]"
      logger.debug "Headers: #{response.header}"
      if ! response.body.is_a?(Sinatra::Helpers::Stream)
        logger.debug "Body:\n"
        logger.debug response.body.join("\n")
      end
    end


    def self.start(server, port, &block)
      Rack::Handler.default.run new(server), Port: port, &block
    end

    def initialize(server)
      @server = server
      super
    end

    module Helpers
      include Rack::Utils

      def logger
        Server.logger
      end

      def server
        @server
      end

      def unsupported
        status 404
        builder :unsupported, layout: true
      end

      def tsn
        headers['TiVo_TCD_ID']
      end

      def select_all_items(children)
        just_items = []
        all = children.dup
        all.each do |child|
          if child.is_a?(TivoHMO::API::Container)
            all.concat(child.children)
          else
            just_items << child
          end
        end
        children = just_items.uniq {|node| node.identifier }
      end

      def sort(items, sort_order)
        sort_order = sort_order.split(/\s*,\s*/)

        sort_order.each do |order|

          reverse = false
          if order[0] == '!'
            reverse = true
            order = order[1..-1]
          end

          case order
            when 'Title'
              items = items.sort_by(&:title)
            when 'CaptureDate'
              items = items.sort_by(&:created_at)
          end

          items = items.reverse if reverse
        end
        items
      end

      def container_url(container)
        url = "/TiVoConnect"
        params = {
            Command: 'QueryContainer',
            Container: container.title_path
        }
        url << "?" << build_query(params)
      end

      def item_url(item)
        item.title_path
      end

      def item_detail_url(item)
        url = "/TiVoConnect"
        container = item.app.title
        file = item.title_path.sub("/#{container}/", '')
        params = {
            Command: 'TVBusQuery',
            Container: container,
            File: file
        }
        url << "?" << build_query(params)
      end

      # to format uuids as needed by tivo in builders
      def format_uuid(s)
        Zlib.crc32(s)
      end

      # to format date/time as needed by tivo in builders
      def format_date(time)
        "0x#{time.to_i.to_s(16)}"
      end

      def format_iso_date(time)
        return "" unless time
        time.utc.strftime("%FT%T.%6N")
      end

      def format_iso_duration(duration)
        return "" unless duration
        seconds = duration % 60
        minutes = (duration / 60) % 60
        hours = (duration / (60 * 60)) % 24
        days = (duration / (60 * 60 * 24)).to_i
        'P%sDT%sH%sM%sS' % [days, hours, minutes, seconds]
      end

      def pad(length, align)
        extra = length % align
        extra = align - extra if extra > 0
        extra
      end

      def tivo_header(item, mime)
        if mime == 'video/x-tivo-mpeg-ts'
          flag = 45
        else
          flag = 13
        end

        item_details_xml = builder :item_details, layout: true, locals: {item: item}
        item_details_xml.force_encoding('ascii-8bit')

        ld = item_details_xml.bytesize
        chunk = item_details_xml + '\0' * (pad(ld, 4) + 4)
        lc = chunk.bytesize
        blocklen = lc * 2 + 40
        padding = pad(blocklen, 1024)

        data = 'TiVo'
        data << [4, flag, 0, padding + blocklen, 2].pack('nnnNn')
        data << [lc + 12, ld, 1, 0].pack('NNnn')
        data << chunk
        data << [lc + 12, ld, 2, 0].pack('NNnn')
        data << chunk
        data << "\0" * padding

        data
      end

      def transliterate(s)
        # unidecoder gem
        s.to_ascii rescue s
      end
    end

    helpers do
      include Helpers
    end

    # Get the xml doc describing the active HME applications
    get '/TiVoConnect' do
      response["Content-Type"] = 'application/xml'

      command = params['Command']

      # pagination
      item_start = (params['ItemStart'] || 0).to_i
      item_count = (params['ItemCount'] || 8).to_i

      # Yes or No, default no
      recurse = config_get(:force_grouping) ? false : (params['Recurse'] == 'Yes')

      # csv of Type, Title, CreationDate, LastChangeDate, Random
      # reverse with preceding !
      sort_order = params['SortOrder']

      # csv of mime types from Details.ContentType, wildcards allowed,
      # negation is preceding !, default/missing is */*
      filter = params['Filter']
      serial = params['SerialNum']

      container_path = params['Container'] || '/'

      anchor_item = params['AnchorItem']
      if anchor_item && anchor_item =~ /QueryContainer/
        query = parse_query(URI(anchor_item).query)
        anchor_item = query['Container']
      end

      anchor_offset = params['AnchorOffset'].to_i

      locals = {
          show_genres: params['DoGenres'],
          item_start: item_start,
          item_count: item_count
      }

      case command

        when 'QueryContainer' then

          container = server.find(container_path)
          halt 404, "No container found for #{container_path}" unless container

          if anchor_item
            anchor = server.find(anchor_item)
            if anchor
              container = anchor.parent
            else
              logger.warn "Anchor not found: #{anchor_item}"
            end
          end

          children = container.children

          children = select_all_items(children) if recurse

          children = sort(children, sort_order) if sort_order && ! container.presorted

          if anchor
            idx = children.index(anchor)
            if idx
              # negative anchor means start N items before the anchor
              # positive means start N items after the anchor
              # ItemStart should be the index of the anchor with offset applied
              anchor_offset = anchor_offset + 1 if anchor_offset < 0
              item_start = idx + anchor_offset
              item_start = 0 if item_start < 0
              locals[:item_start] = item_start
            else
              logger.warn "Anchor not in container: #{container}, #{anchor_item}"
            end
          end

          if item_count < 0
            locals[:item_start] = children.size + item_count
            locals[:item_count] = - item_count
          end

          if container.root?
            builder :server, layout: true,
                    locals: locals.merge(container: container, children: children)
          else
            builder :container, layout: true,
                    locals: locals.merge(container: container, children: children)
          end


        when 'TVBusQuery' then
          container_path = params['Container']
          item_title = params['File']
          halt 404, "Need Container and File params" unless container_path && item_title

          path = "#{container_path}/#{item_title}"
          item = server.find(path)
          halt 404, "No item found for #{path}" unless item

          builder :item_details, layout: true, locals: locals.merge(item: item)

        when 'QueryFormats' then
          sf = params['SourceFormat']
          if sf.to_s.start_with?('video')
            formats = ["video/x-tivo-mpeg"]
            formats << "video/x-tivo-mpeg-ts" # if is_ts_capable(tsn)
            builder :video_formats, layout: true, locals: locals.merge(formats: formats)
          else
            unsupported
          end

        when 'QueryServer' then
          builder :server_info, layout: true

        when 'QueryItem' then
          builder(layout: true) {|xml| xml.QueryItem }

        when 'FlushServer' then
          builder(layout: true) {|xml| xml.FlushServer }

        when 'ResetServer' then
          builder(layout: true) {|xml| xml.ResetServer }

        else
          unsupported
      end

    end

    get '/*' do
      title_path = params[:splat].first
      format = params['Format']
      item = server.find(title_path)
      halt 404, "No item found for #{title_path}" unless item && item.is_a?(TivoHMO::API::Item)

      status 206
      response["Content-Type"] = format

      stream do |out|
        out << tivo_header(item, format)
        item.transcoder.transcode(out, format)
      end

    end

  end
end
