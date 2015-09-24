require_relative '../lib/aws_wrapper'

AwsWrapper.instance.tap do |aws|
  instances = aws.start_instances(2)
  eip = aws.allocate_eip(instances.first) #
  
  # cleanup
  aws.stop_instances(instances)
end
