require_relative '../lib/util/aws_wrapper' # The method we need is in core: no wrapper class needed.
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  ScriptHelper.one_arg_opts(
    opts, config,
    user: 'AWS user name',
    group: 'AWS group name',
    availability_zone: 'Availability Zone'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    debug: 'Turn on debug logging'
  )
  opts.separator('Adds user to group.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :user, :group])

AwsWrapper.new(debug: config[:debug], availability_zone: config[:availability_zone])
  .add_user_to_group(config[:user], config[:group])
