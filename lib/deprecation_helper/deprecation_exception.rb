# typed: strict

module DeprecationHelper
  class DeprecationException < StandardError
    extend T::Sig

    sig { params(message: String).void }
    def initialize(message)
      super message
    end
  end
end
