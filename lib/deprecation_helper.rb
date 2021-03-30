# typed: strict

require 'logger'
require 'sorbet-runtime'
require 'deprecation_helper/private'
require 'deprecation_helper/private/configuration'
require 'deprecation_helper/private/allow_list'

require 'deprecation_helper/strategies/base_strategy_interface'
require 'deprecation_helper/strategies/error_strategy_interface'
require 'deprecation_helper/strategies/raise_error'
require 'deprecation_helper/strategies/log_error'
require 'deprecation_helper/strategies/log_error_and_stacktrace'

require 'deprecation_helper/deprecation_exception'

module DeprecationHelper
  extend T::Sig

  ################################################################################################
  #### PUBLIC API
  ################################################################################################
  sig { params(blk: T.proc.params(arg0: Private::Configuration).void).void }
  def self.configure(&blk)
    blk.call config
  end

  sig do
    params(
      message: String,
      allow_list: T::Array[Regexp],
      deprecation_strategies: T.nilable(T::Array[Strategies::BaseStrategyInterface]),
    ).void
  end
  def self.deprecate!(message, allow_list: [], deprecation_strategies: nil)
    backtrace = caller
    return if Private::AllowList.allowed?(allow_list, backtrace)
    (deprecation_strategies || config.deprecation_strategies).each do |strategy|
      strategy.apply!(message, backtrace)
    end
  end

  # This method is exposed as it might be useful for other systems that want to
  # reuse the global configuration more explicitly
  sig { returns(T::Array[Strategies::BaseStrategyInterface]) }
  def self.deprecation_strategies
    config.deprecation_strategies
  end

  ################################################################################################
  #### PRIVATE API
  ################################################################################################

  sig { returns(Private::Configuration) }
  def self.config
    @config = T.let(@config, T.nilable(Private::Configuration))
    @config ||= Private::Configuration.new
  end

  private_class_method :config
end
