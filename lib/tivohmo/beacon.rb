require 'socket'

module TivoHMO

  # Provides a mechanism for broadcasting the presence of a
  # TivoHMO::Server to Tivo dvrs on the local network
  class Beacon
    include GemLogger::LoggerSupport

    def initialize(service_port, interval: 10, limit: -1)
      @interval = interval
      @limit = limit
      @uid = SecureRandom.uuid
      @socket = UDPSocket.new(Socket::AF_INET)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      @services = ['TiVoMediaServer:%s/http' % service_port]
    end

    def start
      if ! @running
        logger.info "Starting beacon for #{@services.inspect}"
        @running = true
        @broadcast_thread = Thread.new do
          while @running
            broadcast
            sleep(@interval)
            @limit = @limit - 1
            break if @limit == 0
          end
          logger.info "Beacon thread exiting"
        end
      end
    end

    def stop
      logger.info "Stopping beacon"
      @running = false
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
      @socket.send(packet, 0, bcast_ip, bcast_port)
    end

  end
end