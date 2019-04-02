#!/usr/bin/env ruby

require_relative '../lib/client'
require_relative '../lib/config_file'
require 'optparse'
require 'yaml'

def parse
  options = {
    verify: true,
    dest_dir: '.',
  }
  ARGV << '-h' if ARGV.empty?
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
  end.parse!

  options
end

def process_config(config_file)
  ArtifactStorage::ConfigFile.from_file(config_file)
  # TODO: error check
end

# TODO: check for clashes of files, do hash checks?
def main
  opts = parse
  config = process_config(opts[:config_file])
  c = ArtifactStorage::Client.new(config: config.config, user: opts[:user])
  c.fetch(dest: opts[:dest_dir], verify: opts[:verify], match: opts[:match])
end

main
