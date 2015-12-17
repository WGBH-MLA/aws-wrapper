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
    zone_id: 'AWS Zone ID',
    availability_zone: 'Availability Zone'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    debug: 'Turn on debug logging',
    flat: 'Flatten the returned data structure'
  )
  opts.separator('Prints to STDOUT a JSON structure representing the resources under this name.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name])

list = Lister.new(debug: config[:debug], availability_zone: config[:availability_zone])
       .list(config[:zone_id], config[:name])
if config[:flat]
  cnames = list[:cnames]
  instances = cnames.map { |c| c[:instances] }.flatten
  volumes = instances.map { |i| i[:volumes] }.flatten
  # Only groups and key_name will be repeated in tree: only they need uniq.
  list = {
    cnames: cnames.map { |c| c[:cname] },
    elb_names: cnames.map { |c| c[:elb_name] },
    groups: cnames.map { |c| c[:groups] }.flatten.uniq,
    instance_ids: instances.map { |i| i[:instance_id] },
    key_names: instances.map { |i| i[:key_name] }.uniq,
    volume_ids: volumes.map { |v| v[:volume_id] },
    snapshot_ids: volumes.map { |v| v[:snapshot_ids] }.flatten
  }
end

puts JSON.pretty_generate(list).gsub(/\s+([\]}])/, '\1')
