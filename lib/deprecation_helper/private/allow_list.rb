# typed: strict

module DeprecationHelper
  module Private
    class AllowList
      extend T::Sig

      sig { params(allowable_frames: T::Array[Regexp], exception_frames: T::Array[String]).returns(T::Boolean) }
      def self.allowed?(allowable_frames, exception_frames)
        allowable_frames.any? do |allowable_frame|
          exception_frames.any? do |exception_frame|
            exception_frame.match?(allowable_frame)
          end
        end
      end
    end
  end
end
