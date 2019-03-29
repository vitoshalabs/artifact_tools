require 'yaml'

module ArtifactStorage
  class ConfigFile
    attr_reader :config

    # TODO: decide whether to use symbols in the config file
    def initialize(config:)
      # TODO: check for server and dir
      @config = config
    end

    def self.from_file(file)
      # TODO: errors
      ConfigFile.new(config: YAML.load_file(file))
    end

    def save(file)
      File.write(file, @config.to_yaml)
      # TODO: errors
    end

    def append_file(file:, **opts)
      @config['files']
    end
  end
end
