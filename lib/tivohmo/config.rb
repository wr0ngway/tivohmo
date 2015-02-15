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


    def setup(filename)
      @primary_file = File.expand_path(filename)
      @secondary_file = File.expand_path('.' + File.basename(filename), '~')

      @primary_data = Data.new
      @secondary_data = Data.new

      if File.exist?(@primary_file)
        @primary_data = Data.load(@primary_file)
      else
        logger.info "No config at file #{@primary_file}"
      end

      if File.exist?(@secondary_file)
        @secondary_data = Data.load(@secondary_file)
      else
        logger.info "No config at file #{@secondary_file}"
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

      begin
        result = @secondary_data.deep_fetch(*scoped_key)
      rescue Data::UndefinedPathError
        result = @primary_data.deep_fetch(*scoped_key) rescue nil
      end

      result
    end

    def set(scoped_key, value, persist=true)
      scoped_key = Array(scoped_key)

      val_hash = {scoped_key.pop => value}
      scoped_key.reverse.each do |k|
        val_hash = {k => val_hash}
      end

      @secondary_data = @secondary_data.deep_merge(val_hash)
      File.write(@secondary_file, YAML.dump(@secondary_data)) if persist && @secondary_file
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

        def config_register(key, default_value, description)
          raise ArgumentError, "Config '#{key}' already registered" if Config.instance.known_config[key]

          Config.instance.known_config[key] = {
              default_value: default_value,
              description: description,
              source_path: config_path
          }
        end

        def config_get(key)
          result = nil

          path = config_path
          (0..path.size).to_a.reverse.each do |i|
            scoped_key = path[0, i] << key
            result = Config.instance.get(scoped_key)
            break if ! result.nil?
          end

          registered = Config.instance.known_config[key]
          result = registered[:default_value] if result.nil? && registered
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
