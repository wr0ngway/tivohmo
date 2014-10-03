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
      "Runs a HMO server"
    end

    option ["-d", "--debug"],
           :flag, "debug output\n",
           :default => false

    option ["-p", "--port"],
           "PORT", "run server using PORT\n",
           :default => 9032 do |s|
      Integer(s)
    end

    option ["-f", "--configuration"],
           "FILE", "load configuration from given filename\n"

    option ["-a", "--application"],
           "CLASSNAME", "use the given application class\n",
           default: "TivoHMO::Adapters::Filesystem::Application"

    option ["-i", "--identifier"],
           "IDENTIFIER", "use the given application identifier\n"

    option ["-r", "--root"],
           "ROOT", "adds a container root via the application\n",
           multivalued: true

    option ["-c", "--container"],
           "CLASSNAME", "override the application's container class\n"

    option ["-t", "--transcoder"],
           "CLASSNAME", "override the application's transcoder class\n"

    option ["-m", "--metadata"],
           "CLASSNAME", "override the application's metadata class\n"

    option ["-s", "--tsn"],
           "TSN", "Only serve to given TSN\n",
           :multivalued => true

    def execute
      GemLogger.default_logger.level = debug? ? Logger::DEBUG : Logger::INFO

      if configuration
        config = YAML.load_file(configuration)

        # allow cli option to override config file
        set_if_default(:port, config['port'].to_i)
        set_if_default(:application, config['application_class'])
        set_if_default(:container, config['container_class'])
        set_if_default(:transcoder, config['transcoder_class'])
        set_if_default(:metadata, config['metadata_class'])
        set_if_default(:tsn_list, config['tsns'])
        set_if_default(:root_list, config['containers'])
      end

      [application, container, transcoder, metadata].each do |c|
        if c && c.starts_with?('TivoHMO::Adapters::')
          path = c.downcase.split('::')[0..-2].join('/')
          require path
        end
      end

      app_class = application.constantize
      app = app_class.new(identifier)

      app.container_class = container.constantize if container
      app.transcoder_class = transcoder.constantize if transcoder
      app.metadata_class = metadata.constantize if metadata
      app.tsns = tsn_list if tsn_list.present?

      root_list.each do |root|
        ident, title = root.split('@')
        container = app.add_container(ident)
        container.title = title if title.present?
      end

      beacon = TivoHMO::Beacon.new(port)
      beacon.start

      TivoHMO::Server.start(app, port)
    end
  end

  private

  def set_if_default(attr, new_value)
    self.send("#{attr}=", new_value) if self.send(attr) == self.send("default_#{attr}")
  end

end
