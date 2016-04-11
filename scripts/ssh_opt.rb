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
    zone_name: 'AWS Route 53 zone name',
    availability_zone: 'Availability Zone'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    ips_by_tag: 'look up by EC2 name tags and list IPs',
    ips_by_dns: 'look up by DNS names and list IPs',
    debug: 'Turn on debug logging'
  )
  opts.separator('Prints to STDOUT the appropriate arguments for sshing')
  opts.separator('... or just lists the IPs.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_name, :name])

if config[:ips_by_tag]
  puts SshOpter.new(debug: config[:debug], availability_zone: config[:availability_zone])
    .ips_by_tag(config[:name]).join("\n")
elsif config[:ips_by_dns]
  puts SshOpter.new(debug: config[:debug], availability_zone: config[:availability_zone])
    .ip_by_dns(config[:zone_name], config[:name])
else
  prefix = /^demo\./
  if config[:name] !~ prefix
    warn 'The supplied name must start with "demo.": You should not touch production.'
    exit 1
  end

  puts SshOpter.new(debug: config[:debug], availability_zone: config[:availability_zone])
    .ssh_opts(config[:zone_name], config[:name])
end
