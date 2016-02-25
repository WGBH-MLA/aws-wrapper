require_relative '../lib/util/ssh_opter'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ssh `#{File.basename(__FILE__)} ...`"
  ScriptHelper.one_arg_opts(
    opts, config,
    name: 'Name to be used for PK, EBS, DNS, etc.',
    zone_id: 'AWS Zone ID',
    availability_zone: 'Availability Zone'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    just_ips: 'Just return a list of IPs'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    debug: 'Turn on debug logging'
  )
  opts.separator('Prints to STDOUT the appropriate arguments for sshing.')
  opts.separator('(For safety\'s sake, the script only allows connections to demo.)')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name])

if config[:just_ips]
  puts SshOpter.new(debug: config[:debug], availability_zone: config[:availability_zone])
    .just_ips(config[:zone_id], config[:name]).join("\n")
else
  prefix = /^demo\./
  if config[:name] !~ prefix
    warn 'The supplied name must start with "demo.": You should not touch production.'
    exit 1
  end

  puts SshOpter.new(debug: config[:debug], availability_zone: config[:availability_zone])
    .ssh_opts(config[:zone_id], config[:name])
end
