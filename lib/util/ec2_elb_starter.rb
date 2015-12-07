require_relative 'aws_wrapper'

class Ec2ElbStarter < AwsWrapper
  
  def start(zone_id, name, size_in_gb)
    create_key(name)
    LOGGER.info("Created PK for #{name}")
    
    create_group(name)
    add_current_user_to_group(name)
    LOGGER.info("Created group #{name}, and added current user")
    
    instance_ids = start_instances(2, name).map(&:instance_id)
    LOGGER.info("Started 2 EC2 instances #{instance_ids}")
    
    instance_ids.each do |instance_id|
      create_and_attach_volume(instance_id, '/dev/sdb', size_in_gb)
    end
    LOGGER.info("Attached EBS volume to each instance")
    
    elb_names = elb_names(name)
    elb_a_names = elb_names.map{ |name| create_elb(name) }
    instance_ids.zip(elb_names).each do |instance_id, elb_name|
      register_instance_with_elb(instance_id, elb_name)
    end
    LOGGER.info("Created load balancers and registered instances")
    
    # Maybe this would be better managed than inline?
    # But then that would be another thing to clean up.
    put_group_policy(name, {
      'Effect' => 'Allow',
      'Action' => 'elasticloadbalancing:*', # TODO: tighten
      'Resource' => elb_names.map { |elb_name| elb_arn(elb_name) }
      # TODO: pull zone and account ID from somewhere.
    })
    LOGGER.info("Create group policy for ELB")
    
    name_target_pairs = cname_pair(name).zip(elb_a_names)
    create_dns_cname_records(zone_id, name_target_pairs)
    LOGGER.info("Created CNAMEs")
  end
  
end
