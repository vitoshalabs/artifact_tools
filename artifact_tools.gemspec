Gem::Specification.new do |s|
  s.authors = ["VL"]
  s.name = 'artifact-tools'
  s.version = '0.0.1'
  s.summary = 'Provides tools to manage repository artifacts.'
  s.files = Dir['lib/**'] + Dir['bin/*']
  s.required_ruby_version = '> 2.4.0'
  s.executables << 'artifact_download' << 'artifact_upload'
end
