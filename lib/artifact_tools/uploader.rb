# frozen_string_literal: true

require 'artifact_tools/client'
require 'artifact_tools/config_file'
require 'optparse'
require 'yaml'

module ArtifactTools
  # Uploader allows the user to upload files to a store specified by
  # {ConfigFile}.
  class Uploader
    include ArtifactTools::Hasher
    # Upload requested files
    #
    # @param config_file [String] Path to configuration file
    # @param append [Boolean] Whether to append files to config file
    # @param files [Array(String)] Paths to files to upload
    def initialize(config_file:, files:, append: false)
      # TODO: check for clashes of files, do hash checks?
      @config_file = config_file
      @append = append
      @config = load_config(@config_file)
      c = ArtifactTools::Client.new(config: @config.config)
      files.each do |file|
        update_file(c, file)
      end
      @config.save(config_file)
    end

    @default_append_opt = false
    @parse_opts_handlers = {
      ['-c FILE', '--configuration=FILE', 'Pass configuration file.'] => lambda { |_opts, v, options|
        options[:config_file] = v
      },
      ['-a', '--append',
       "Append uploaded files to configuration file, if missing. Default: #{@default_append_opt}."] =>
      ->(_opts, v, options) { options[:append] = v },
      ['-h', '--help', 'Show this message'] => lambda { |opts, _v, _options|
        puts opts
        exit
      }
    }

    # Parse command line options to options suitable to Downloader.new
    #
    # @param arguments [Array(String)] Command line options to parse and use.
    #   Hint: pass ARGV
    def self.parse(arguments)
      options = { append: @default_append_opt }
      arguments << '-h' if arguments.empty?
      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"
        @parse_opts_handlers.each do |args, handler|
          opts.on(*args) { |v|  handler.call(opts, v, options) }
        end
      end.parse!(arguments)

      raise OptionParser::MissingArgument, 'Missing -c/--configuration option' unless options.key?(:config_file)

      options.merge({ files: arguments.dup })
    end

    private

    def load_config(config_file)
      ArtifactTools::ConfigFile.from_file(config_file)
    end

    def relative_to_config(file, config_file)
      file = File.expand_path(file)
      config_file = File.expand_path(config_file)
      config_file_dirname = File.dirname(config_file)
      return nil unless file.start_with?(config_file_dirname)

      file[(config_file_dirname.length + 1)..]
    end

    # update the current file remotely and append it to the config if needed
    def update_file(client, file)
      client.put(file: file)
      hash = file_hash(file)
      puts "#{hash} #{file}"
      return unless @append

      rel_path = relative_to_config(file, @config_file)
      raise "#{file} is not relative to config: #{@config_file}" unless rel_path

      @config.append_file(file: file, store_path: rel_path, hash: hash)
    end
  end
end
