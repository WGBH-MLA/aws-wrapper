require_relative '../lib/util/lister'
require_relative '../lib/script_helper'
require 'optparse'
require 'json'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'Name to be used for PK, EBS, DNS, etc.') do |n|
    config[:name] = n
  end
  opts.on('--zone_id ZONE', 'AWS Zone ID') do |z|
    config[:zone_id] = z
  end
  opts.on('--availability_zone', 'Availability Zone') do |z|
    config[:availability_zone] = z
  end
  opts.on('--flat', 'Flatten the returned datastructure') do
    config[:flat] = true
  end
  opts.on('--debug', 'Turn on debugging') do
    config[:debug] = true
  end
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name])

list = Lister.new(debug: config[:debug], availability_zone: config[:availability_zone]).list(config[:zone_id], config[:name])
if config[:flat]
  cnames = list[:cnames]
  instances = cnames.map { |c| c[:instances] }.flatten
  volumes = instances.map { |i| i[:volumes] }.flatten
  # Only groups and key_name will be repeated in tree: only they need uniq.
  puts JSON.pretty_generate(
    cnames: cnames.map { |c| c[:cname] },
    elb_names: cnames.map { |c| c[:elb_name] },
    groups: cnames.map { |c| c[:groups] }.flatten.uniq,
    instance_ids: instances.map { |i| i[:instance_id] },
    key_names: instances.map { |i| i[:key_name] }.uniq,
    volume_ids: volumes.map { |v| v[:volume_id] },
    snapshot_ids: volumes.map { |v| v[:snapshot_ids] }.flatten
  )
else
  puts JSON.pretty_generate(list).gsub(/\s+([\]}])/, '\1')
end
