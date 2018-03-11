lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'async_service'

Gem::Specification.new do |spec|
  spec.name          = 'async_service'
  spec.version       = AsyncService::VERSION
  spec.authors       = ['Isty001']
  spec.email         = ['isty001@gmail.com']

  spec.summary       = 'Asynchronous service'
  spec.description   = 'Small lib, for creating message queue based, async services'
  spec.homepage      = 'https://github.com/isty001/async_service'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'redis', '~> 4.0'

  spec.add_development_dependency 'minitest', '~> 5.1'
end
