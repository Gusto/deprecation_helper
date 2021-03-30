# typed: strict

module DeprecationHelper
  module Strategies
    class LogErrorAndStacktrace
      include BaseStrategyInterface

      extend T::Sig

      sig { params(logger: T.nilable(Logger)).void }
      def initialize(logger: nil)
        @logger = T.let(logger || Logger.new(STDOUT), Logger)
      end

      sig { override.params(message: String, backtrace: T::Array[String]).void }
      def apply!(message, backtrace) # rubocop:disable Lint/UnusedMethodArgument
        @logger.warn({ message: message, backtrace: backtrace})
      end
    end
  end
end
