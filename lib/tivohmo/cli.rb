require 'clamp'
require 'yaml'
require 'active_support/core_ext/string'
require 'sigdump/setup'
require 'tivohmo'

module TivoHMO

  # The command line interface to tivohmo
  class CLI < Clamp::Command
    include GemLogger::LoggerSupport

    def self.description
      desc = <<-DESC
        Runs a HMO server.  Specify one or more applications to show up as top level
        shares in the TiVo Now Playing view.  The application, identifier,
        transcoder, metadata options can be given in groups to apply the transcoder
        and metadata to each application - uses the application's default if not given

        e.g.

        tivohmo -a TivoHMO::Adapters::Filesystem::Application -i ~/Video/Movies \\
                -a TivoHMO::Adapters::Filesystem::Application -i ~/Video/TV

        to run two top level filesystem video serving apps for different dirs,
        or

        tivohmo -i "My Videos@~/Video"

        to run the single default filesystem app with a custom title
      DESC
      desc.split("\n").collect(&:strip).join("\n")
    end

    option ["-d", "--debug"],
           :flag, "debug output\n",
           default: false

    option ["-p", "--port"],
           "PORT", "run server using PORT\n",
           default: 9032 do |s|
      Integer(s)
    end

    option ["-f", "--configuration"],
           "FILE", "load configuration from given filename\n"

    option ["-a", "--application"],
           "CLASSNAME", "use the given application class\n",
           default: ["TivoHMO::Adapters::Filesystem::Application"],
           multivalued: true

    option ["-i", "--identifier"],
           "IDENTIFIER", "use the given application identifier\n" +
           "a string that has meaning to the application\n" +
           "give an optional title like <title>@<ident>\n",
           multivalued: true

    option ["-t", "--transcoder"],
           "CLASSNAME", "override the application's transcoder class\n",
           multivalued: true

    option ["-m", "--metadata"],
           "CLASSNAME", "override the application's metadata class\n",
           multivalued: true

    option ["-s", "--tsn"],
           "TSN", "Only serve to given TSN\n",
           multivalued: true

    option ["-b", "--beacon"],
           "LIMIT:INTERVAL", "configure beacon limit and/or interval\n"

    def execute
      GemLogger.default_logger.level = debug? ? Logger::DEBUG : Logger::INFO

      if configuration
        config = YAML.load_file(configuration)

        # allow cli option to override config file
        set_if_default(:port, config['port'].to_i)
      end

      (application_list + transcoder_list + metadata_list).each do |c|
        if c && c.starts_with?('TivoHMO::Adapters::')
          path = c.downcase.split('::')[0..-2].join('/')
          require path
        end
      end

      server = TivoHMO::API::Server.new

      apps_with_config = application_list.zip(identifier_list,
                                              transcoder_list,
                                              metadata_list)

      apps_with_config.each do |app_classname, identifier, transcoder, metadata|
        title, ident = identifier.split("@")
        ident, title = title, nil unless ident

        app_class = app_classname.constantize
        app = app_class.new(ident)

        if title
          app.title = title
        else
          app.title = "#{app.title} on #{server.title}"
        end

        app.transcoder_class = transcoder.constantize if transcoder
        app.metadata_class = metadata.constantize if metadata
        server.add_child(app)
      end

      TivoHMO::Server.start(server, port) do |s|
        limit, interval = beacon.split(":")
        opts = {}
        opts[:limit] = limit.to_i if limit.present?
        opts[:interval] = interval.to_i if interval.present?
        TivoHMO::Beacon.new(port, **opts).start
      end
    end
  end

  private

  def set_if_default(attr, new_value)
    self.send("#{attr}=", new_value) if self.send(attr) == self.send("default_#{attr}")
  end

end
