# DeprecationHelper

[![Build status](https://badge.buildkite.com/ca0732598feeb90c404e6883a2d79ad32610ff356020f11639.svg?branch=main)](https://buildkite.com/gusto/deprecationhelper)

The purpose of this gem is to help Ruby developers change code safely. It provides a basic framework for deprecating code. Since Ruby is an untyped language, you can't be sure when ceratin types of changes you're trying to make, such as deleting or renaming a method, will break production. This gem is provides an opinionated roadmap for deprecating code.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'deprecation_helper'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install deprecation_helper

## Usage
### Configuration
First, you'll need to configure `DeprecationHelper`.

Here is an example configuration:
```ruby
DeprecationHelper.configure do |config|
  if Rails.env.test? || Rails.env.development?
    config.deprecation_strategies = [
      DeprecationHelper::Strategies::LogError.new(logger: Rails.logger),
      DeprecationHelper::Strategies::RaiseError.new,
    ]
  else
    config.deprecation_strategies = [
      DeprecationHelper::Strategies::LogError.new(logger: Rails.logger),
      MyCustomStrategy.new, # See more on this below
    ]
  end
end
```

In this configuration, we always log an error in any environment. In the test environment, this allows to generate TODO lists of code that is exercised by your test suite that is using deprecated methods. These TODO lists can then be passed into the allow list (see below). In test and development, an error is raised as well, which in this configuration forces users to either add the deprecations to the TODO list or to address them prior to landing the deprecation.

Note that global configuration is optional -- you can also pass in `deprecation_strategies` directly to your `deprecate!` call (see the advanced usage section below).

### Deprecating Code
There is one main method which is called with a string
```ruby
DeprecationHelper.deprecate!('your message value')
```

By inlining these into your code, when the deprecation is called, it will apply the strategies that you've configured.

### Allow lists
The main method accept an `allow_list` argument, as such:
```ruby
DeprecationHelper.deprecate!('your message value', allow_list: [/your/, /allow/, /list/]))
```

If your callstack (determined by `Kernel#caller`) matches *any* element in the allow list, then no deprecation strategy will be invoked -- the deprecation will be skipped. It is recommended to use `allow_list` primarily as a TODO list.

Note also that your allow list entries should be as specific to avoid unintended matches, especially if the entries represent a todo list of specific lines from specific files.

**Examples of allow lists**

Here are a couple of examples of `allow_list` values that you might want:
- `bin/rails` - Perhaps you want to permit everything that happens in your rails console
- `my_method_wrapper` - In some cases, you want to just use this gem to help you find all places that use the code and wrap them in something that makes it safe to use the deprecated method, but easier to grep for. Perhaps you have a class like:
```ruby
class MyDeprecator
  def self.my_method_wrapper
    yield
  end
end
```
This class doesn't do anything, but now you can call `MyDeprecator.my_method_wrapper { my_deprecated_code }` and it will be allow-listed using `my_method_wrapper` as the allow-list value.
- `some_exempt_folder` - Perhaps you'd like an entire folder to be exempt from this deprecation for the time being, for whatever reason
- `factory_bot` - Perhaps a gem like `factory_bot` or another test only piece of code is using your deprecated functionality and you don't mind permitting it to unblock other tests.

### Deprecation Strategies
There are several strategies, here's what they do:

**Strategy: Do nothing on use of deprecated code**

Where to find it: Configure `deprecation_strategies` to be an empty list (this is also the default)
This might be useful if you want to take no action in certain environments.

**Strategy: Raising on use of deprecated code**

Where to find it: `DeprecationHelper::Strategies::RaiseError`

This is useful if you believe you've already addressed all deprecations in the environment that uses this strategy OR perhaps if the use of the deprecated code is more negatively impactful than raising.

Note that this strategy will construct a `DeprecationHelper::DeprecationException` with the message equal to the input value to `deprecate!` and raise that error.

**Strategy: Logging on use of deprecated code**

Where to find it: `DeprecationHelper::Strategies::LogError`

This is useful if you want to generate an allow list to stop the bleeding.

**Strategy: Report to your bug tracking tool on use of deprecated code**

Where to find it: This you'll need to create yourself, since it has a dependency on bugsnag.
One option is to use the `ThrottledBugsnag` or `Bugsnag` gem, by creating your own deprecation strategy (see advanced usage below).

### Advanced Usage
**Overriding global configuration**

You can pass in an array of `deprecation_strategies` to `deprecate!` if you'd like to override the global configuration for `DeprecationHelper`.

**Creating your own deprecation strategies**

You can construct your own deprecation strategies by implementing any `StrategyInterface` class, which means including the class and implementing the method(s) it requires.

Here are the interfaces you can include to construct your own strategies:
- `DeprecationHelper::Strategies::ErrorStrategyInterface`
- `DeprecationHelper::Strategies::BaseStrategyInterface`

Here is an example of them being used:
```ruby
class SlackNotifierDeprecationStrategy
  include DeprecationHelper::Strategies::BaseStrategyInterface
  extend T::Sig

  sig { override.params(message: String, logger: T.nilable(Logger)).void }
  def apply!(message, logger: nil)
    # This takes in an exception that is message equal to the message passed into `deprecate!`
    SlackNotifier.notify(message)
  end
end

class BugsnagDeprecationStrategy
  include DeprecationHelper::Strategies::ErrorStrategyInterface
  extend T::Sig

  sig { override.params(exception: StandardError, logger: T.nilable(Logger)).void }
  def apply_to_exception!(exception, logger: nil)
    # This takes in an exception that is a `DeprecationHelper::DeprecationException`
    # with a `message` value equal to the message passed into `deprecate!`
    Bugsnag.notify(exception)
  end
end
```
You can create your own deprecation strategy by including StrategyInterface and implementing the method `apply!` that takes in an `exception` and an optional `logger`.

Here is an example:
```ruby
class BugsnagDeprecationStrategy
  include DeprecationHelper::Strategies::BaseStrategyInterface
  extend T::Sig
  sig { override.params(exception: StandardError).void }
  def apply!(exception)
    ThrottledBugsnag.notify(exception) # or Bugsnag.notify(exception)
  end
end
```

This is useful to report instances of use of deprecated code in production without actually raising an error in production. The use of ThrottledBugsnag is recommended in case there are high-frequency, untested code paths that use the deprecated code to prevent sampling or throttling issues in your bug tracking tool.

## Types of things to deprecate
There are endless things you might deprecate, here are some examples
- Public API change - A method call. You might want to deprecate a method, either deleting it entirely or renaming it. Tossing a `deprecate!` call in there will let clients know when they need to migrate.
- Public API change - arguments. You might want to change an optional argument to be required, add or remove an argument, or change an argument's type. You can check for future incompatibility and use this gem when a client is invoking deprecated behavior.
- A product scenario. You might want to deprecate when a query method returns `nil` when the thing you are looking for, such as a `User`, should always exist.
- A database condition. Perhaps you want to add a `non-nil` column, but aren't positive that `nil` is never persisted into that column (when querying the column is not enough, because `nil` could happen in a non-terminal condition in an ongoing request). If you use something like `ActiveRecord`, you could create a validator for this:
```ruby
# Usage:
#
# class User < ApplicationRecord
#   validates_with PresenceOfColumnSoftValidator, columns: [:name]
# end
#
class PresenceOfColumnSoftValidator < ActiveModel::Validator
  extend T::Sig

  sig { params(model: T.untyped).returns(T::Boolean) }
  def validate(model)
    columns_to_validate = options[:columns]
    columns_to_validate.each do |column|
      next unless model.public_send(column).nil?
      DeprecationHelper.deprecate!(
        "#{model.class.name}##{column} should never be nil",
      )
    end

    true
  end
end
```
- A graceful exit. A place in your code might `rescue` some arbitrary condition, and you'd like to later on stop rescuing. You can use `deprecate!` as a safe way to remove that rescue.
- Any general assumption. You might want to make a simplifying change to your application, but that change relies on a hard-to-statically-verify assumption in your system, such as some other state in the system, or some sequence of operations. You can use `deprecate!` as a general way to verify assumptions, and call `deprecate!` when your assumption turns out to be false.

## Why you might not want to use this gem
In an ideal world, we could "deprecate" by simply calling `raise "This is deprecated"`, and we've fully covered all supported scenarios in our test suite, and running our test suite would reveal all deprecations before we go to production

In another ideal world, we recognize our test suite isn't perfect, but as a forcing function, we continue to `raise` and backfill tests as errors come into production.

However if your application is like the one I work in, a lot of supported and critical scenarios are in fact untested. This means applying this approach will potentially have negative customer impact.

When using this gem, it is generally recommended to backfill test coverage for any deprecation that isn't caught by your test suite. Ultimately, when this gem is used, it means you cannot fully trust your test suite. As a long-term goal, it might be advantageous to move towards getting to a place where you can confidently just call `raise` in your codebase and rely on your test suite. Another better systematic approach is to statically type your code base, in which case certain types of deprecations, such as removing a method, can be caught before going to production even without a test suite.

## Development

Run `bundle exec rspec` to run all tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/deprecation_helper.
