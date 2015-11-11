require_relative 'aws_wrapper'

class Ec2ElbStarter < AwsWrapper
  
  def start(zone_id, name)
    instances = start_instances(2)
    
    # TODO: Start ELBs
    # TODO: Assign EC2s to ELBs
    # TODO: Create DNS CNAMES for ELBs
  end
  
end
