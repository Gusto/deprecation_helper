# typed: strict

module DeprecationHelper
  module Strategies
    module ErrorStrategyInterface
      extend T::Sig
      extend T::Helpers
      include BaseStrategyInterface

      abstract!

      sig { override.params(message: String, backtrace: T::Array[String]).void }
      def apply!(message, backtrace)
        exception = DeprecationException.new(message)
        exception.set_backtrace(backtrace)
        apply_to_exception!(exception)
      end

      sig { abstract.params(exception: StandardError).void }
      def apply_to_exception!(exception)
      end
    end
  end
end
