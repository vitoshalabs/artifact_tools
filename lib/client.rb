require 'net/ssh'
require 'net/scp'
require 'fileutils'
require 'byebug'

module ArtifactStorage
  class Client
    # @param config [Hash] Configuration
    def initialize(config:)
      required_fields = ['server', 'dir', 'files']
      raise "Invalid config" unless config.keys.all? { |k| required_fields.include?(k) }
      @config = config
      @ssh = Net::SSH.start(@config['server'], nil, non_interactive: true)
    end

    def fetch(file:nil, dest:nil)
      files = @config['files'].keys
      files = file if file
      files.each do |entry|
        remote = compose_remote(entry)
        local = compose_local(dest, entry)
        @ssh.scp.download!(remote, local)
      end
    end

    # dir?
    def put(file:)
    end

    private
    def compose_remote(file)
      hash = @config['files'][file]['hash']
      basename = File.basename(file)
      "#{@config['dir']}/#{hash}/#{basename}"
    end

    def ensure_path_exists(local)
      dirname = File.dirname(local)
      return if File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    def compose_local(dest, file)
      local = file
      local = "#{dest}/#{local}" if dest
      ensure_path_exists(local)
      local
    end
  end
end
