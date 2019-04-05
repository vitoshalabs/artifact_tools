require 'yaml'
require 'artifact_tools/hasher'

module ArtifactTools
  # Store configuration information about artifacts and where they are stored.
  #
  # It has to contain at least the fields from {REQUIRED_FIELDS} while allowing
  # any key/value which has a value for the user.
  class ConfigFile
    include ArtifactTools::Hasher
    attr_reader :config
    REQUIRED_FIELDS = ['server', 'dir', 'files']

    # Initialize config file
    #
    # @param config [Hash] Provide configuration. Mandatory fields are {REQUIRED_FIELDS}
    def initialize(config:)
      raise "Invalid config" unless REQUIRED_FIELDS.all? { |k| config.keys.include?(k) }
      @config = config
    end

    # Create ConfigFile from file in YAML format
    #
    # @param file [String] Path to file in YAML format.
    def self.from_file(file)
      ConfigFile.new(config: YAML.load_file(file))
      # Leave error propagation as this is development tool
    end

    # Saves configuration to file
    #
    # @param file [String] Save in this file. Overwrites the file if present.
    def save(file)
      File.write(file, @config.to_yaml)
      # Leave error propagation as this is development tool
    end

    # Append file to configuration.
    #
    # @param file [String] Path to the file to store in the configuration
    # @param store_path [String] Use this path as key in the configuration. Optional, if omitted uses file
    # @param opts [Hash] Additional fields to store for the file
    def append_file(file:, store_path:nil, **opts)
      store_path = file unless store_path
      @config['files'][store_path] = opts
      @config['files'][store_path]['hash'] = file_hash(file)
    end
  end
end
