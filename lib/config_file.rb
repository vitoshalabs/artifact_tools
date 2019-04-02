require 'yaml'
require_relative 'hasher'

module ArtifactStorage
  class ConfigFile
    include ArtifactStorage::Hasher
    attr_reader :config
    REQUIRED_FIELDS = ['server', 'dir', 'files']

    def initialize(config:)
      raise "Invalid config" unless REQUIRED_FIELDS.all? { |k| config.keys.include?(k) }
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
