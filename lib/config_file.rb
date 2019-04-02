require 'yaml'
require_relative 'hasher'

module ArtifactStorage
  class ConfigFile
    include ArtifactStorage::Hasher
    attr_reader :config

    def initialize(config:)
      # TODO: check for server and dir
      @config = config
    end

    def self.from_file(file)
      ConfigFile.new(config: YAML.load_file(file))
      # Leave error propagation as this is development tool
    end

    def save(file)
      File.write(file, @config.to_yaml)
      # Leave error propagation as this is development tool
    end

    def append_file(file:, **opts)
      @config['files']
    end
  end
end
