require 'builder'
require 'sinatra/base'
require 'active_support/core_ext/string'
require 'zlib'
require 'time'

module TivoHMO

  # The http server for serving the Application/Container/Item tree,
  # including an endpoint for transcoding video from the Item to the
  # tivo format
  class Server < Sinatra::Base
    include GemLogger::LoggerSupport

    enable :logging
    set :root, File.expand_path("../server", __FILE__)
    set :reload_templates, true
    set :builder, :content_type => 'text/xml'

    def self.start(server, port, &block)
      Rack::Handler.default.run new(server), Port: port, &block
    end

    def initialize(server)
      @server = server
      super
    end

    helpers do
      include Rack::Utils

      def server
        @server
      end

      def unsupported
        status 404
        erb :unsupported, layout: true
      end

      def tsn
        headers['TiVo_TCD_ID']
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
        "/#{item.title_path}"
      end

      def item_detail_url(item)
        url = "/TiVoConnect"
        container = item.app.title
        file = item.title_path.sub(container, '')
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
        hours = duration / (60 * 60)
        'P%sDT%sH%sM%sS' % [0, hours, minutes, seconds]
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

    end

    # before do
    #   if request.ip != '192.168.1.12'
    #     puts "#{request.ip} halted"
    #     halt 403
    #   end
    #   puts "#{request.ip} ok"
    # end

    # before do
    #   if server.tsns && ! server.tsns.include?(tsn)
    #     msg = "TSN not allowed access: #{tsn}"
    #     logger.warn msg
    #     halt 403, msg
    #   end
    # end

    after do
      if logger.level == Logger::DEBUG
        logger.debug "Response to #{request.ip} for #{request.url} [#{response.status}]:"
        logger.debug response.body.join("\n") unless response.body.is_a?(Sinatra::Helpers::Stream)
      end
    end

    # Get the xml doc describing the active HME applications
    get '/TiVoConnect' do
      logger.info "Tivo Connected: #{request.url}"
      command = params['Command']

      # pagination
      item_start = (params['ItemStart'] || 0).to_i
      item_count = (params['ItemCount'] || 8).to_i

      # Yes or No, default no
      recurse = (params['Recurse'] == 'Yes')

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

          children = container.children
          children = sort(children, sort_order) if sort_order

          if anchor_item
            anchor = server.find(anchor_item)
            if anchor
              idx = children.index(anchor)
              if idx
                # -1 means show starting at the anchor item
                # ItemStart should be the index of the anchor
                anchor_offset = anchor_offset + 1 if anchor_offset < 0
                item_start = idx + anchor_offset
                item_start = 0 if item_start < 0
                locals[:item_start] = item_start
              else
                logger.warn "Anchor not in container: #{container}, #{anchor_item}"
              end
            else
              logger.warn "Anchor not found: #{anchor_item}"
            end
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
          path = "#{container_path}#{item_title}"

          item = server.find(path)
          halt 404, "No item found for #{path}" unless item

          builder :item_details, layout: true, locals: locals.merge(item: item)

        when 'QueryFormats' then
          sf = params['SourceFormat']
          if sf.start_with?('video')
            formats = ["video/x-tivo-mpeg"]
            formats << "video/x-tivo-mpeg-ts" # if is_ts_capable(tsn)
            builder :video_formats, layout: true, locals: locals.merge(formats: formats)
          else
            unsupported
          end

        when 'QueryServer' then
          builder :server_info, layout: true

        when 'QueryItem' then
          status 200
          body ""

        when 'FlushServer' then
          status 200
          body ""

        when 'ResetServer' then
          status 200
          body ""

        else
          unsupported
      end

    end

    get '/*' do

      logger.info "Tivo Requesting Item: #{request.url}"

      title_path = params[:splat].join('/')
      format = params['Format']
      item = server.find(title_path)
      halt 404, "No item found for #{title_path}" unless item && item.is_a?(TivoHMO::API::Item)

      status 206
      response["Content-Type"] = format

      stream do |out|
        out << tivo_header(item, format)
        item.transcoder.transcode(out)
      end

    end

  end
end
