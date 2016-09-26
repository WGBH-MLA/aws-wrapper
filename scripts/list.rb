#!/usr/bin/env ruby

require_relative '../lib/util/lister'
require_relative '../lib/script_helper'
require 'optparse'
require 'json'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  ScriptHelper.one_arg_opts(
    opts, config,
    name: 'Name to be used for PK, EBS, DNS, etc.',
    availability_zone: 'Availability Zone'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    debug: 'Turn on debug logging',
    flat: 'Flatten the returned data structure'
  )
  opts.separator('Prints to STDOUT a JSON structure representing the resources under this name.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :name])

list = Lister.new(debug: config[:debug], availability_zone: config[:availability_zone])
       .list(config[:name], config[:flat])

puts JSON.pretty_generate(list).gsub(/\s+([\]}])/, '\1')
