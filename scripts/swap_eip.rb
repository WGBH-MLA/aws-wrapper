require_relative '../lib/aws_wrapper'

public_ip = ARGV.shift
instance_id = ARGV.shift

AwsWrapper.instance.tap do |aws|
  instance = aws.lookup_instance(instance_id)
  aws.assign_eip(public_ip, instance)
end