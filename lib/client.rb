require 'net/ssh'
require 'net/scp'
require 'fileutils'
require 'digest'
require 'pry-byebug'

module ArtifactStorage
  class HashMismatchError < RuntimeError
  end

  class Client
    # @param config [Hash] Configuration
    def initialize(config:)
      required_fields = ['server', 'dir', 'files']
      raise "Invalid config" unless config.keys.all? { |k| required_fields.include?(k) }
      @config = config
      @ssh = Net::SSH.start(@config['server'], nil, non_interactive: true)
    end

    def fetch(file:nil, dest:nil, verify: false)
      files = @config['files'].keys
      files = file if file
      files.each do |entry|
        entry_hash = @config['files'][entry]['hash']
        remote = compose_remote(entry, entry_hash)
        local = compose_local(dest, entry)
        @ssh.scp.download!(remote, local)
        verify(entry_hash, local) if verify
      end
    end

    # dir?
    def put(file:)
      hash = hash_file(file)
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

    def hash_algo
      # TODO: decide on used algorithm
      Digest::SHA1
    end

    def hash_file(path)
      hash_algo.file(path)
    end

    def verify(expected_hash, path)
      actual_hash = hash_file(path)
      if expected_hash != actual_hash.hexdigest
        raise HashMismatchError, "File #{path} has hash: #{actual_hash} while it should have: #{expected_hash}"
      end
    end
  end
end
