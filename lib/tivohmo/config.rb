require 'hashie'

module TivoHMO

  class Config
    include GemLogger::LoggerSupport
    include Singleton

    def setup(filename)
      @primary_file = File.expand_path(filename)
      @secondary_file = File.expand_path('.' + File.basename(filename), '~')

      @primary_data = Hashie::Mash.new
      @secondary_data = Hashie::Mash.new

      if File.exist?(@primary_file)
        @primary_data = Hashie::Mash.load(@primary_file)
        @primary_data.extend Hashie::Extensions::DeepFetch
      else
        logger.info "No config at file #{@primary_file}"
      end

      if File.exist?(@secondary_file)
        @secondary_data = Hashie::Mash.load(@secondary_file)
        @secondary_data.extend Hashie::Extensions::DeepFetch
      else
        logger.info "No config at file #{@secondary_file}"
      end
    end

    def known_config
      @known_config ||= {}
    end

    def get(scoped_key)
      scoped_key = Array(scoped_key)
      result = @secondary_data.deep_fetch(scoped_key)
      result = @primary_data.deep_fetch(scoped_key) if result.nil?
      result
    end

    def set(scoped_key, value, persist=true)
      scoped_key = Array(scoped_key)

      val_hash = {scoped_key.pop => value}
      scoped_key.reverse.each do |k|
        val_hash = {k => val_hash}
      end

      @secondary_data = @secondary_data.deep_merge(new_hash)
      File.write(@secondary_file, YAML.dump(@secondary_data)) if persist
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
          (path.size..1).to_a.reverse.each do |i|
            scoped_key = path[0, i] << key
            result = Config.instance.get(scoped_key)
            break if ! result.nil?
          end

          result = Config.instance.known_config[key][:default_value] if result.nil?
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
