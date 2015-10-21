require_relative '../lib/ec2_manager'

public_ip = ARGV.shift
instance_id = ARGV.shift

Ec2Manager.instance.tap do |aws|
  instance = aws.lookup_instance(instance_id)
  aws.assign_eip(public_ip, instance)
end