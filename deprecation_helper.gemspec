lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'deprecation_helper'
  spec.version       = '0.1.0'
  spec.authors       = ['Alex Evanczuk']
  spec.email         = ['alex.evanczuk@gusto.com']

  spec.summary       = 'This is a simple, low-dependency gem for managing deprecations.'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\u0000").reject { |f| f.match(%r{A(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sorbet-runtime', '~> 0.5.6293'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'sorbet', '~> 0.5.6293'
end
