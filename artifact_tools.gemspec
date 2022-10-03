# frozen_string_literal: true

require_relative 'lib/artifact_tools/version'

Gem::Specification.new do |s|
  s.authors = ['Vitosha Labs Open Source team']
  s.name = 'artifact_tools'
  s.version = ArtifactTools::VERSION
  s.summary = 'Provides tools to manage repository artifacts.'
  s.homepage = 'https://github.com/vitoshalabs/artifact_tools'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.license = 'MIT'

  s.required_ruby_version = '> 2.7.0'

  s.files = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.executables << 'artifact_download' << 'artifact_upload'
  s.require_paths = ['lib']

  s.add_dependency 'ed25519', '~> 1.3'
  s.add_dependency 'bcrypt_pbkdf', '~> 1.1'
  s.add_dependency 'net-scp', '~> 3.0'
  s.add_dependency 'net-ssh', '~> 6'

  s.add_development_dependency 'bundler', '~> 2.0'
  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'rspec', '~> 3.0'

  s.add_development_dependency 'rspec-simplecov', '~> 0.2'
  s.add_development_dependency 'rubocop-rspec', '~> 2.0'
  s.add_development_dependency 'simplecov', '~> 0.16'
end
