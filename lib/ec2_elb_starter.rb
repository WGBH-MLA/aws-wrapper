require_relative 'aws_wrapper'

class Ec2ElbStarter < AwsWrapper
  
  def start(zone_id, name)
    instance_ids = start_instances(2).map(&:instance_id)
    elb_names = [1,2].map{ |i| "#{name}-#{i}" }
    elb_a_names = elb_names.map{ |name| create_elb(name) }
    instance_ids.zip(elb_names).each do |instance_id, elb_name|
      register_instance_with_elb(instance_id, elb_name)
    end
    # TODO: Exercise this.
    [name, "demo.#{name}"].zip(elb_a_names).each do |domain_name, elb_target_name|
      request_create_dns_cname_record(zone_id, domain_name, elb_target_name)
    end
    # TODO: Confirm DNS update.
  end
  
end
