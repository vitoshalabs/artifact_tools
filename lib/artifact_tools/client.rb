require 'net/ssh'
require 'net/scp'
require 'fileutils'
require 'digest'
require 'artifact_tools/hasher'

module ArtifactTools
  # Notifies that there was a mismatch between expected hash of the
  # file(according to the configuration file) and the actual hash of the
  # fetched file
  class HashMismatchError < RuntimeError
  end

  # Use an object of this class to put/fetch files from storage specified with {ConfigFile}
  class Client
    include ArtifactTools::Hasher

    # @param config [Hash] Configuration
    # @param user [String] User name to connect to server with, overrides
    #   ARTIFACT_STORAGE_USER and the on stored in config
    def initialize(config:, user:nil)
      @config = config
      user ||= ENV['ARTIFACT_STORAGE_USER'] || @config['user']
      @ssh = Net::SSH.start(@config['server'], user, non_interactive: true)
    end

    # Fetch a file from store
    #
    # @param file [String] Path to file to fetch. Fetches all files from config if omitted.
    # @param dest [String] Optional prefix to add to local path of the file being fetched. Uses cwd if omitted.
    # @param match [Regexp] Optionally fetch only files matching this pattern.
    # @param verify [Boolean] Whether to verify the checksum after the file is received. Slows the fetch.
    #
    # @raise [HashMismatchError] In case checksum doesn't match the one stored in the config file.
    def fetch(file:nil, dest:nil, match:nil, verify: false)
      files = @config['files'].keys
      files = [file] if file
      files.each do |entry|
        next if match && !entry.match?(match)

        entry_hash = @config['files'][entry]['hash']
        remote = compose_remote(entry, entry_hash)
        local = compose_local(dest, entry)
        @ssh.scp.download!(remote, local)
        verify(entry_hash, local) if verify
      end
    end

    # Put a file to storage
    #
    # @param file [String] Path to the file to store.
    def put(file:)
      hash = file_hash(file)
      remote = compose_remote(file, hash)
      ensure_remote_path_exists(remote)
      @ssh.scp.upload!(file, remote)
    end

    private
    def compose_remote(file, hash)
      basename = File.basename(file)
      "#{@config['dir']}/#{hash}/#{basename}"
    end

    def ensure_path_exists(local)
      dirname = File.dirname(local)
      return if File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    def ensure_remote_path_exists(remote)
      dirname = File.dirname(remote)
      return if File.directory?(dirname)
      @ssh.exec!("mkdir -p #{dirname}")
    end

    def compose_local(dest, file)
      local = file
      local = "#{dest}/#{local}" if dest
      ensure_path_exists(local)
      local
    end

    def verify(expected_hash, path)
      actual_hash = file_hash(path)
      if expected_hash != actual_hash
        raise HashMismatchError, "File #{path} has hash: #{actual_hash} while it should have: #{expected_hash}"
      end
    end
  end
end
