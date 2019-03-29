#!/usr/bin/env ruby

require_relative '../lib/client'
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

    # TODO: pass default
    opts.on("-v", "--[no-]verify", "Verify hash on downloaded files") do |v|
      options[:verify] = v
    end

    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end.parse!

  options
end

def process_config(config)
  YAML.load_file(config)
  # TODO: error check
end

# TODO: check for clashes of files, do hash checks?
def main
  opts = parse
  config = process_config(opts[:config_file])
  c = ArtifactStorage::Client.new(config: config)
  c.fetch(dest: opts[:dest_dir], verify: opts[:verify])
end

main
