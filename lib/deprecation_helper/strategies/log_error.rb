# typed: strict

module DeprecationHelper
  module Strategies
    class LogError
      include BaseStrategyInterface

      extend T::Sig

      sig { params(logger: T.untyped).void }
      def initialize(logger: nil)
        @logger = T.let(logger || Logger.new(STDOUT), T.untyped)
      end

      sig { override.params(message: String, backtrace: T::Array[String]).void }
      def apply!(message, backtrace) # rubocop:disable Lint/UnusedMethodArgument
        @logger.warn(message)
      end
    end
  end
end
