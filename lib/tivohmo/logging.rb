require 'gem_logger'
require 'logging'
require 'active_support/concern'

Logging.format_as :inspect
Logging.backtrace true

Logging.color_scheme(
    'bright',
    levels: {
        info: :green,
        warn: :yellow,
        error: :red,
        fatal: [:white, :on_red]
    },
    date: :blue,
    logger: :cyan,
    message: :magenta
)

Logging.appenders.stdout(
    'stdout',
    layout: Logging.layouts.pattern(
        pattern: '[%d] %-5l %c{2} %m\n',
        color_scheme: 'bright'
    )
)

Logging.logger.root.appenders = Logging.appenders.stdout
Logging.logger.root.level = :info

module TivoHMO
  module LoggingConcern
    extend ActiveSupport::Concern

    def logger
      Logging.logger[self.class]
    end

    module ClassMethods
      def logger
        Logging.logger[self]
      end
    end

  end
end

GemLogger.default_logger = Logging.logger.root
GemLogger.logger_concern = TivoHMO::LoggingConcern
