require_relative "lib/artifact_tools/version"

Gem::Specification.new do |s|
  s.authors = ["VL"]
  s.name = 'artifact_tools'
  s.version = ArtifactTools::VERSION
  s.summary = 'Provides tools to manage repository artifacts.'
  s.files = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.required_ruby_version = '> 2.4.0'
  s.executables << 'artifact_download' << 'artifact_upload'
end
