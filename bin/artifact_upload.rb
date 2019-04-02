#!/usr/bin/env ruby

require_relative '../lib/client'
require_relative '../lib/config_file'
require 'optparse'
require 'yaml'

def parse
  options = {
    append: false,
  }
  ARGV << '-h' if ARGV.empty?
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
  end.parse!

  options[:files] = ARGV.dup

  options
end

def process_config(config_file)
  ArtifactStorage::ConfigFile.from_file(config_file)
end

# TODO: check for clashes of files, do hash checks?
def main
  opts = parse
  config = process_config(opts[:config_file])
  c = ArtifactStorage::Client.new(config: config.config)
  opts[:files].each do |file|
    c.put(file: file)
    config.append_file(file:file) if opts[:append]
  end
  config.save(opts[:config_file])
end

main
