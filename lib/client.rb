require 'net/ssh'
require 'net/scp'
require 'fileutils'
require 'digest'
# TODO: Remove relative when gem
require_relative 'hasher'

module ArtifactStorage
  class HashMismatchError < RuntimeError
  end

  class Client
    include ArtifactStorage::Hasher

    # @param config [Hash] Configuration
    # @param user [String] User name to connect to server with, overrides ARTIFACT_STORAGE_USER and config['user']
    def initialize(config:, user:nil)
      @config = config
      user ||= ENV['ARTIFACT_STORAGE_USER'] || @config['user']
      @ssh = Net::SSH.start(@config['server'], user, non_interactive: true)
    end

    def fetch(file:nil, dest:nil, match:nil, verify: false)
      files = @config['files'].keys
      files = file if file
      files.each do |entry|
        next if match and not entry.match?(match)
        entry_hash = @config['files'][entry]['hash']
        remote = compose_remote(entry, entry_hash)
        local = compose_local(dest, entry)
        @ssh.scp.download!(remote, local)
        verify(entry_hash, local) if verify
      end
    end

    # dir?
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
