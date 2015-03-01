require 'clamp'
require 'yaml'
require 'active_support/core_ext/string'
require 'sigdump/setup'
require 'tivohmo'
require 'open-uri'

module TivoHMO

  # The command line interface to tivohmo
  class CLI < Clamp::Command
    include GemLogger::LoggerSupport

    def self.description
      desc = <<-DESC
        TivoHMO version #{TivoHMO::VERSION}

        Runs a HMO server.  Specify one or more applications to show up as top level
        shares in the TiVo Now Playing view.  The application, identifier,
        transcoder, metadata options can be given in groups to apply the transcoder
        and metadata to each application - uses the application's default if not given

        e.g.

        tivohmo -t Movies
                  -a TivoHMO::Adapters::Filesystem::Application \\
                  -i ~/Video/Movies \\
                -t "TV Shows" \\
                  -a TivoHMO::Adapters::Filesystem::Application \\
                  -i ~/Video/TV

        to run two top level filesystem video serving apps for different dirs, or

        tivohmo -t Vids \\
                  -a TivoHMO::Adapters::Filesystem::Application \\
                  -i ~/Video

        to run the single filesystem app, or

        tivohmo -t PlexVideo \\
                  -a TivoHMO::Adapters::Plex::Application \\
                  -i localhost

        to run the single plex app
      DESC
      desc.split("\n").collect(&:strip).join("\n")
    end

    option ["-d", "--debug"],
           :flag, "debug output\n",
           default: false

    option ["-v", "--version"],
           :flag, "print version and exit\n",
           default: false

    option ["-r", "--preload"],
           :flag, "Preloads all lazy container listings\n",
           default: false

    option ["-l", "--logfile"],
           "FILE", "log to given file\n"

    option ["-p", "--port"],
           "PORT", "run server using PORT\n",
           default: 9032 do |s|
      Integer(s)
    end

    option ["-f", "--configuration"],
           "FILE", "load configuration from given filename\n"

    option ["-s", "--settings"],
           "FILE", "a writable file for storing runtime settings\n"

    option ["-t", "--title"],
           "TITLE", "setup an application for the given title\n",
           multivalued: true

    option ["-a", "--application"],
           "CLASSNAME", "use the given application class\n",
           multivalued: true

    option ["-i", "--identifier"],
           "IDENTIFIER", "use the given application identifier\n" +
           "a string that has meaning to the application\n",
           multivalued: true

    option ["-T", "--transcoder"],
           "CLASSNAME", "override the application's transcoder class\n",
           multivalued: true

    option ["-M", "--metadata"],
           "CLASSNAME", "override the application's metadata class\n",
           multivalued: true

    option ["-b", "--beacon"],
           "LIMIT:INTERVAL", "configure beacon limit and/or interval\n"

    option ["-l", "--install"],
           :flag, "install tivohmo into your system\n"

    def execute

      if version?
        puts "TivoHMO Version #{TivoHMO::VERSION}"
        return
      end

      install_tivohmo if install?

      c = File.expand_path(configuration) if configuration
      s = File.expand_path(settings) if settings
      TivoHMO::Config.instance.setup(c, s)

      setup_logging

      logger.info "TivoHMO #{TivoHMO::VERSION} starting up"

      # allow cli option to override config file
      set_if_default(:port, TivoHMO::Config.instance.get(:port).try(:to_i))

      server = TivoHMO::API::Server.new
      apps = setup_applications
      apps.each {|app| server.add_child(app) }

      preload_containers(server) if preload?

      opts = {}
      set_if_default(:beacon, TivoHMO::Config.instance.get(:beacon))
      if beacon.present?
        limit, interval = beacon.split(":")
        opts[:limit] = limit.to_i if limit.present?
        opts[:interval] = interval.to_i if interval.present?
      end
      notifier = TivoHMO::Beacon.new(port, **opts)

      TivoHMO::Server.start(server, port) do |s|
        wait_for_server { notifier.start }
      end
    end

    private

    def setup_logging
      set_if_default(:debug, TivoHMO::Config.instance.get(:debug))
      Logging.logger.root.level = :debug if debug?

      set_if_default(:logfile, TivoHMO::Config.instance.get(:logfile))
      if logfile.present?
        appender = Logging.appenders.rolling_file(
            logfile,
            truncate: true,
            age: 'daily',
            keep: 3,
            layout: Logging.layouts.pattern(
                pattern: Logging.appenders.stdout.layout.pattern
            )
        )

        # hack to assign stdout/err to logfile if logging to file
        io = appender.instance_variable_get(:@io)
        $stdout = $stderr = io

        Logging.logger.root.appenders = appender
      end
    end

    def set_if_default(attr, new_value)
      opt = self.class.find_option("--#{attr}")
      raise "Unknonwn cli attribute" unless opt
      self.send("#{attr}=", new_value) if new_value && self.send(opt.read_method) == opt.default_value
    end

    def load_adapter(clazz)
      if clazz && clazz.starts_with?('TivoHMO::Adapters::')
        path = clazz.downcase.split('::')[0..-2].join('/')
        require path
      end
    end

    def setup_applications
      app_specs = TivoHMO::Config.instance.get(:applications) || {}

      title_list.each_with_index do |title, i|
        app = app_specs[title]
        app_was_in_config = app.present?
        app = {} unless app_was_in_config

        app[:application] = application_list[i] if application_list[i]
        signal_usage_error "an application class is needed for each application" unless app[:application]

        app[:identifier] = identifier_list[i] if identifier_list[i]
        signal_usage_error "an initializer is needed for each application" unless app[:identifier]


        app[:transcoder] = transcoder_list[i] if transcoder_list[i]
        app[:metadata] = metadata_list[i] if metadata_list[i]

        logger.debug "Merged app: #{title} - #{app.inspect}"
        app_specs[title] = app unless app_was_in_config
      end

      signal_usage_error "at least one application is required" unless app_specs.present?

      apps = app_specs.collect do |title, app_spec|
        logger.debug "Adding app: #{title} - #{app_spec.inspect}"
        load_adapter(app_spec[:application])

        app_class = app_spec[:application].constantize
        app = app_class.new(app_spec[:identifier])
        app.title = title

        if app_spec[:transcoder]
          load_adapter(app_spec[:transcoder])
          app.transcoder_class = app_spec[:transcoder].constantize
        end

        if app_spec[:metadata]
          load_adapter(app_spec[:metadata])
          app.metadata_class = app_spec[:metadata].constantize
        end

        app
      end

      apps
    end

    def preload_containers(server)
      Thread.new do
        logger.info "Preloading lazily cached containers"
        queue = server.children.dup
        queue.each do |i|
          logger.debug("Loading children for #{i.title_path}")
          queue.concat(i.children)
        end
        logger.info "Preload complete"
      end
    end

    def wait_for_server
      Thread.new do
        while true
          begin
            open("http://localhost:#{port}/TiVoConnect?Command=QueryServer") {}
            yield
            break
          rescue Exception => e
          end
        end
      end
    end

    # Opens the file for writing by root
    def sudo_open(path, mode, perms=0755, &block)
      open("|sudo tee #{path} > /dev/null", perms, &block)
    end

    def get_binding(config)
      binding
    end

    def install_file(src, dst, config={}, sudo=false)
      src = File.expand_path(src)
      dst = File.expand_path(dst)

      block = Proc.new do |f|
        template = ERB.new(File.read(src), nil, "-")
        result = template.result(get_binding(config))
        f.write(result)
      end

      puts "Installing #{dst}"

      if sudo
        sudo_open(dst, "w", &block)
      else
        open(dst, "w", &block)
      end
    end

    def install_tivohmo
      puts "Installing TivoHMO"

      contrib_path = File.expand_path("../../../contrib", __FILE__)

      case RUBY_PLATFORM
        when /darwin/

          config = {
              daemon_config: "~/Library/LaunchAgents/tivohmo.plist",
              configuration: "~/Library/Preferences/tivohmo.yml",
              logfile: "~/Library/Logs/tivohmo.log",
              settings: "~/Library/Preferences/tivohmo.runtime.yml"
          }

          install_file("#{contrib_path}/tivohmo.yml", config[:configuration], config)
          install_file("#{contrib_path}/tivohmo.plist", config[:daemon_config], config)

          puts "TivoHMO installed"
          puts "To start tivohmo, execute the command:"
          puts "\tlaunchctl load #{config[:daemon_config]}"
          puts "To stop tivohmo, execute the command:"
          puts "\tlaunchctl unload #{config[:daemon_config]}"

        when /linux/

          config = {
              daemon_config: "/etc/init/tivohmo.conf",
              configuration: "/etc/tivohmo.yml",
              logfile: "/var/log/tivohmo.log",
              settings: "/var/run/tivohmo.runtime.yml"
          }

          puts "Sudo password needed to install files"
          install_file("#{contrib_path}/tivohmo.yml", config[:configuration], config, true)
          install_file("#{contrib_path}/tivohmo.conf", config[:daemon_config], config, true)

          puts "TivoHMO installed"
          puts "To start tivohmo, execute the command:"
          puts "\tsudo service tivohmo start"
          puts "To stop tivohmo, execute the command:"
          puts "\tsudo service tivohmo stop"

        else
          $stderr.puts "Unsupported OS: #{RUBY_PLATFORM}"
          exit(1)
      end

      exit(0)
    end

  end

end
