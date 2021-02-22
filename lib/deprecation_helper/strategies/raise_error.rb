# typed: strict

module DeprecationHelper
  module Strategies
    # This strategy raises the original error
    class RaiseError
      include BaseStrategyInterface

      extend T::Sig

      sig { override.params(message: String, backtrace: T::Array[String]).void }
      def apply!(message, backtrace)
        exception = DeprecationException.new(message)
        exception.set_backtrace(backtrace)
        raise exception
      end
    end
  end
end
