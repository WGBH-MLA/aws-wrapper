require_relative '../lib/ec2_manager'

Ec2Manager.instance.tap do |aws|
  instances = aws.start_instances(1)
  #eip = aws.allocate_eip(instances.first)
  
  # cleanup
  # TODO: Looks like the stop request succeeds but then successive status checks give
  # Aws::Waiters::Errors::FailureStateError
  #aws.stop_instances(instances)
end
