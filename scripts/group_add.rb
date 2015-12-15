require_relative '../lib/util/group_adder'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--user USER', 'AWS user name') do |u|
    config[:user] = u
  end
  opts.on('--group GROUP', 'AWS group name') do |g|
    config[:group] = g
  end
  opts.on('--availability_zone', 'Availability Zone') do |z|
    config[:availability_zone] = z
  end
  opts.on('--debug', 'Turn on debugging') do
    config[:debug] = true
  end
  opts.separator('Adds user to group.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :user, :group])

GroupAdder.new(debug: config[:debug], availability_zone: config[:availability_zone]).add_user_to_group(config[:user], config[:group])
