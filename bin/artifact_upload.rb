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

def relative_to_config(file, config_file)
  file = File.expand_path(file)
  config_file = File.expand_path(config_file)
  config_file_dirname = File.dirname(config_file)
  return nil unless file.start_with?(config_file_dirname)
  file[(config_file_dirname.length + 1)..-1]
end

# TODO: check for clashes of files, do hash checks?
def main
  opts = parse
  config = process_config(opts[:config_file])
  c = ArtifactStorage::Client.new(config: config.config)
  opts[:files].each do |file|
    c.put(file: file)
    next unless opts[:append]
    rel_path = relative_to_config(file, opts[:config_file])
    raise "#{file} is not relative to config: #{opts[:config_file]}" unless rel_path
    config.append_file(file:file, store_path:rel_path)
  end
  config.save(opts[:config_file])
end

main
