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
    # @param user [String] User to use for download connection
    # @param append [Boolean] Whether to append files to config file
    # @param files [Array(String)] Paths to files to upload
    def initialize(config_file:, user:nil, files:, append:false)
      # TODO: check for clashes of files, do hash checks?
      config = load_config(config_file)
      c = ArtifactTools::Client.new(config: config.config)
      files.each do |file|
        c.put(file: file)
        hash = file_hash(file)
        puts "#{hash} #{file}"
        next unless append
        rel_path = relative_to_config(file, config_file)
        raise "#{file} is not relative to config: #{config_file}" unless rel_path
        config.append_file(file:file, store_path:rel_path, hash: hash)
      end
      config.save(config_file)
    end

    # Parse command line options to options suitable to Downloader.new
    #
    # @param arguments [Array(String)] Command line options to parse and use.
    #   Hint: pass ARGV
    def self.parse(arguments)
      options = {
        append: false,
      }
      arguments << '-h' if arguments.empty?
      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"

        opts.on("-c FILE", "--configuration=FILE", "Pass configuration file.") do |v|
          options[:config_file] = v
        end

        opts.on("-a", "--append", "Append uploaded files to configuration file, if missing. Default: #{options[:append]}.") do |v|
          options[:append] = v
        end

        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end.parse!(arguments)

      raise OptionParser::MissingArgument.new("Missing -c/--configuration option") unless options.has_key?(:config_file)

      options[:files] = arguments.dup

      options
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
      file[(config_file_dirname.length + 1)..-1]
    end
  end
end
