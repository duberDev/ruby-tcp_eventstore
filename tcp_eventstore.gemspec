# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'tcp_eventstore'
  spec.version       = '0.0.1'
  spec.authors       = ['Jonathan Dextraze']
  spec.email         = ['jonathan.dextraze@dexdo.com']

  spec.summary       = %q{TcpEventstore is a TCP connector to the Greg's Event Store.}
  spec.description   = %q{TcpEventstore is a TCP connector to the Greg's Event Store.}
  spec.homepage      = 'https://github.com/jdextraze/ruby-tcp_eventstore'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'

  spec.add_dependency 'google-protobuf'
end
