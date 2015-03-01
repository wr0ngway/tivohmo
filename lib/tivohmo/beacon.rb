require 'socket'

module TivoHMO

  # Provides a mechanism for broadcasting the presence of a
  # TivoHMO::Server to Tivo dvrs on the local network
  class Beacon
    include GemLogger::LoggerSupport

    def initialize(service_port, limit: -1, interval: 10)
      @interval = interval
      @limit = limit
      @uid = SecureRandom.uuid
      @services = ['TiVoMediaServer:%s/http' % service_port]
      @running = false
    end

    def start
      if ! @running
        logger.info "Starting beacon(limit=#@limit, interval=#@interval) for #{@services.inspect}"
        @running = true
        @broadcast_thread = Thread.new do
          while @running
            begin
              broadcast
            rescue => e
              logger.log_exception(e, "Ignoring exception in beacon thread", level: :warn)
            end
            sleep(@interval)
            @limit = @limit - 1
            break if @limit == 0
          end
          @running = false
          logger.info "Beacon thread exiting"
        end
      end
    end

    def stop
      logger.info "Stopping beacon"
      @running = false
    end

    def join
      @broadcast_thread.join
    end

    def beacon_data(method)
      payload = {
          tivoconnect: 1,
          method: method,
          identity: "{#{@uid}}",
          machine: Socket.gethostname,
          platform: 'pc/tivohmo',
          services: @services.join(';'),
          swversion: TivoHMO::VERSION
      }
      data = payload.collect {|k,v| "#{k}=#{v}" }.join("\n") << "\n"
      data
    end

    def broadcast
      bcast_ip = '<broadcast>' #'255.255.255.255'
      bcast_port = 2190
      packet = beacon_data('broadcast')
      logger.debug "Sending beacon packet: #{packet}"
      socket = UDPSocket.new(Socket::AF_INET)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      socket.send(packet, 0, bcast_ip, bcast_port)
    end

  end
end