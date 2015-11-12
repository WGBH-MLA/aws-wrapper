require_relative 'aws_wrapper'

class Ec2ElbStarter < AwsWrapper
  
  def start(zone_id, name)
    instance_ids = start_instances(2).map(&:instance_id)
    elb_names = [1,2].map{ |i| "#{name}-#{i}" }
    elb_a_names = elb_names.map{ |name| create_elb(name) }
    instance_ids.zip(elb_names).each do |instance_id, elb_name|
      register_instance_with_elb(instance_id, elb_name)
    end
    
    # TODO: Create DNS CNAMES for ELBs
  end
  
end
