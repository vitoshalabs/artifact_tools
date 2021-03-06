# frozen_string_literal: true

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

    REQUIRED_FIELDS = %w[server dir files].freeze

    # Initialize config file
    #
    # @param config [Hash] Provide configuration. Mandatory fields are {REQUIRED_FIELDS}
    def initialize(config:)
      raise 'Invalid config' unless REQUIRED_FIELDS.all? { |k| config.keys.include?(k) }

      raise 'Invalid config' unless [NilClass, Hash].any? { |klass| config['files'].is_a?(klass) }

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
    #
    # @note If file exists in the config with key *store_path* then its
    #   properties will be merged, where new ones will have priority.
    def append_file(file:, store_path: nil, **opts)
      store_path ||= file

      # Convert symbols to String
      opts = hash_keys_to_strings(opts)

      @config['files'] ||= {}
      @config['files'][store_path] = opts
      @config['files'][store_path]['hash'] ||= file_hash(file)
    end

    private

    def hash_keys_to_strings(hash)
      hash.transform_keys(&:to_s)
    end
  end
end
