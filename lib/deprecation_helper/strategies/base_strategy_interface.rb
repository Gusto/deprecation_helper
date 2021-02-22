# typed: strict

module DeprecationHelper
  module Strategies
    # This is the interface for all strategies
    module BaseStrategyInterface
      extend T::Sig
      extend T::Helpers

      interface!

      sig { abstract.params(message: String, backtrace: T::Array[String]).void }
      def apply!(message, backtrace)
      end
    end
  end
end
