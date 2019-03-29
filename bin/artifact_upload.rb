#!/usr/bin/env ruby

require_relative '../lib/client'
require 'optparse'
require 'yaml'

def parse
  options = {
    append: false,
  }
  ARGV << '-h' if ARGV.empty?
  OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"

    opts.on("-c FILE", "--configuration=FILE", "Pass configuration file.") do |f|
      options[:config_file] = f
    end

    opts.on("-a", "--append", "Append uploaded files to configuration file, if missing.") do |f|
      options[:config_file] = f
    end

    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end.parse!

  options[:files] = ARGV.dup

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
  opts[:files].each do |file|
    c.put(file: file)
  end
end

main
