require_relative '../lib/aws_wrapper'
require 'logger'

AwsWrapper.instance.tap do |aws|
  instances = aws.start_instances(1)
  # TODO: We've run out of EIPs
  #eip = aws.allocate_eip(instances.first) #
  
  # cleanup
  aws.stop_instances(instances)
end
