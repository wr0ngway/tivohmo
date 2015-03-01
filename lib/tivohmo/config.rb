require 'hashie'

module TivoHMO

  class Config
    include GemLogger::LoggerSupport
    include Singleton

    def initialize
      super
      @primary_data = Data.new
      @secondary_data = Data.new
    end


    def setup(primary_filename, secondary_filename=nil)
      @primary_file = primary_filename
      @secondary_file = secondary_filename

      @primary_data = Data.new
      @secondary_data = Data.new

      if File.exist?(@primary_file.to_s)
        logger.info "Loading primary config from: '#{@primary_file}'"
        @primary_data = Data.load(@primary_file)
      else
        logger.info "No primary config at file: '#{@primary_file}'"
      end

      # get secondary config from primary if present and not set explictly
      secondary = get(:settings)
      @secondary_file ||= File.expand_path(secondary) if secondary

      if File.exist?(@secondary_file.to_s)
        logger.info "Loading secondary config from: '#{@secondary_file}'"
        @secondary_data = Data.load(@secondary_file)
      else
        logger.info "No secondary config at file: '#{@secondary_file}'"
      end
    end

    def reset
      @primary_file = @secondary_file = nil
      @primary_data = @secondary_data = nil
      @known_config = nil
    end

    def known_config
      @known_config ||= {}
    end

    def get(scoped_key)
      scoped_key = Array(scoped_key)
      result = nil

      key = scoped_key.pop
      path = scoped_key
      (0..path.size).to_a.reverse.each do |i|
        partial = path[0, i] << key

        begin
          result = @secondary_data.deep_fetch(*partial)
        rescue Data::UndefinedPathError
          begin
            result = @primary_data.deep_fetch(*partial)
          rescue Data::UndefinedPathError
          end
        end

        break if ! result.nil?
      end

      if result.nil?
        registered = known_config[key]
        result = registered[:default_value] if registered
      end

      result
    end

    def set(scoped_key, value, persist=true)
      scoped_key = Array(scoped_key)
      key = scoped_key.pop

      val_hash = {key => value}
      scoped_key.reverse.each do |k|
        val_hash = {k => val_hash}
      end

      @secondary_data = @secondary_data.deep_merge(val_hash)
      File.write(@secondary_file, YAML.dump(@secondary_data)) if persist && @secondary_file

      registered = known_config[key]
      if registered && registered[:on_change]
        registered[:on_change].call
      end
    end

    class Data < ::Hash
      include Hashie::Extensions::IndifferentAccess
      include Hashie::Extensions::DeepFetch

      def self.load(filename)
        h = Hashie::Extensions::Parsers::YamlErbParser.perform(filename)
        new.replace(h)
      end
    end

    module Mixin
      extend ActiveSupport::Concern

      included do
        delegate :config_register,
                 :config_get,
                 :config_set,
                 :to => "self.class"

      end

      module ClassMethods

        def config_register(key, default_value, description, &on_change_block)
          raise ArgumentError, "Config '#{key}' already registered" if Config.instance.known_config[key]

          Config.instance.known_config[key] = {
              default_value: default_value,
              description: description,
              source_path: config_path,
              on_change: on_change_block
          }
        end

        def config_get(key)
          scoped_key = config_path << key
          result = Config.instance.get(scoped_key)
          result
        end

        def config_set(key, value)
          Config.instance.set(key, value)
        end

        private

        def config_path
          path = self.name.underscore
          path = path.sub(/.*tivo_hmo\//, '')
          pieces = path.split('/')
          pieces
        end

      end
    end

  end

end
