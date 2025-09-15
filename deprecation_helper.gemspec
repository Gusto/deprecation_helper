lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'deprecation_helper'
  spec.version       = '0.4.0'
  spec.authors       = ['Alex Evanczuk']
  spec.email         = ['alex.evanczuk@gusto.com']

  spec.summary       = 'This is a simple, low-dependency gem for managing deprecations.'
  spec.homepage      = 'https://github.com/Gusto/deprecation_helper'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir["LICENSE", "README.md", "lib/**/*"]

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sorbet-runtime', '>= 0.5.6293'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'tapioca'
end
