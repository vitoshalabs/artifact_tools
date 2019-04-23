require 'artifact_tools/client'
require 'artifact_tools/config_file'
require 'optparse'
require 'yaml'

module ArtifactTools
  # Downloader allows the user to fetch files from a store specified. All this
  # information is provided by {ConfigFile}.
  class Downloader

    # Downloads requested files
    #
    # @param config_file [String] Path to configuration file
    # @param user [String] User to use for download connection
    # @param dest_dir [String] Where to download artifacts to
    # @param verify [Boolean] Whether to verify checksums after download.
    # @param match [Regexp] Whether to verify checksums after download.
    def initialize(config_file:, dest_dir:, user:nil, verify: true, match:nil)
      config = load_config(config_file)
      c = ArtifactTools::Client.new(config: config.config, user: user)
      c.fetch(dest: dest_dir, verify: verify, match: match)
    end

    # Parse command line options to options suitable to Downloader.new
    #
    # @param arguments [Array(String)] Command line options to parse and use.
    #   Hint: pass ARGV
    def self.parse(arguments)
      options = {
        verify: true,
        dest_dir: '.',
      }
      arguments << '-h' if arguments.empty?
      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"

        opts.on("-c FILE", "--configuration=FILE", "Pass configuration file") do |f|
          options[:config_file] = f
        end

        opts.on("-d DIR", "--destination=DIR", "Store files in directory") do |d|
          options[:dest_dir] = d
        end

        opts.on("-v", "--[no-]verify", TrueClass, "Verify hash on downloaded files. Default: #{options[:verify]}.") do |v|
          options[:verify] = v
        end

        opts.on("-u USER", "--user=USER", "Access server with this username") do |u|
          options[:user] = u
        end

        opts.on("-m REGEXP", "--match=REGEXP", Regexp, "Download only file which match regular expression") do |v|
          options[:match] = v
        end

        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end.parse!(arguments)

      raise OptionParser::MissingArgument.new("Missing -c/--configuration option") unless options.has_key?(:config_file)

      options
    end

    private

    def load_config(config_file)
      ArtifactTools::ConfigFile.from_file(config_file)
      # TODO: error check
    end
  end
end
