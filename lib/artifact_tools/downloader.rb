# frozen_string_literal: true

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
    # @param [Hash] args the arguments for downloading artifacts
    # @argument args :config_file [String] Path to configuration file
    # @argument args :user [String] User to use for download connection
    # @argument args :dest_dir [String] Where to download artifacts to
    # @argument args :verify [Boolean] Whether to verify checksums after download.
    # @argument args :force [Boolean] Whether to download files even if they are already
    #   present with the exected hash
    # @argument args :match [Regexp] Whether to verify checksums after download.
    def initialize(args = { verify: true, force: false })
      config = load_config(args[:config_file])
      c = ArtifactTools::Client.new(config: config.config, user: args[:user])
      c.fetch(dest: args[:dest_dir], verify: args[:verify], match: args[:match], force: args[:force])
    end

    @default_opts = {
      verify: true,
      force: false,
      dest_dir: '.'
    }
    @parse_opts_handlers = {
      ['-c FILE', '--configuration=FILE', 'Pass configuration file'] => lambda { |f, options, _opts|
        options[:config_file] = f
      },
      ['-d DIR', '--destination=DIR', 'Store files in directory'] => lambda { |d, options, _opts|
        options[:dest_dir] = d
      },
      ['-v', '--[no-]verify', TrueClass, "Verify hash on downloaded files. Default: #{@default_opts[:verify]}."] =>
      lambda { |v, options, _opts|
        options[:verify] = v
      },
      [
        '-f', '--[no-]force', TrueClass,
        "Force download of files if they are present with expected hash. Default: #{@default_opts[:force]}."
      ] => lambda { |v, options, _opts|
        options[:force] = v
      },
      ['-u USER', '--user=USER', 'Access server with this username'] => ->(u, options, _opts) { options[:user] = u },
      ['-m REGEXP', '--match=REGEXP', Regexp, 'Download only file which match regular expression'] =>
      lambda { |v, options, _opts|
        options[:match] = v
      },
      ['-h', '--help', 'Show this message'] => lambda { |_h, _options, opts|
        puts opts
        exit
      }
    }
    # Parse command line options to options suitable to Downloader.new
    #
    # @param arguments [Array(String)] Command line options to parse and use.
    #   Hint: pass ARGV
    def self.parse(arguments)
      options = @default_opts
      arguments << '-h' if arguments.empty?
      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"
        @parse_opts_handlers.each do |args, handler|
          opts.on(*args) { |v|  handler.call(v, options, opts) }
        end
      end.parse!(arguments)

      raise OptionParser::MissingArgument, 'Missing -c/--configuration option' unless options.key?(:config_file)

      options
    end

    private

    def load_config(config_file)
      ArtifactTools::ConfigFile.from_file(config_file)
      # TODO: error check
    end
  end
end
