require_relative '../lib/aws_wrapper'

AwsWrapper.instance.tap do |aws|
  instances = aws.start_instances(1)
  # TODO: We've run out of EIPs
  #eip = aws.allocate_eip(instances.first) #
  
  # cleanup
  # TODO: Looks like the stop request succeeds but then successive status checks give
  # Aws::Waiters::Errors::FailureStateError
  #aws.stop_instances(instances)
end
