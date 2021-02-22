# typed: strict

module DeprecationHelper
  module Private
    class Configuration
      extend T::Sig

      sig { params(deprecation_strategies: T::Array[DeprecationHelper::Strategies::BaseStrategyInterface]).void }
      attr_writer :deprecation_strategies

      sig { void }
      def initialize
        @deprecation_strategies = T.let(@deprecation_strategies, T.nilable(T::Array[DeprecationHelper::Strategies::BaseStrategyInterface]))
      end

      sig { returns(T::Array[DeprecationHelper::Strategies::BaseStrategyInterface]) }
      def deprecation_strategies
        @deprecation_strategies || []
      end
    end
  end
end
