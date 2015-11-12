require_relative 'aws_wrapper'

class Ec2ElbStarter < AwsWrapper
  
  def start(zone_id, name)
    key_name = name
    create_key(name)
    instance_ids = start_instances(2, key_name).map(&:instance_id)
    elb_names = ['a', 'b'].map{ |i| "#{name.gsub(/\W+/, '-')}-#{i}".downcase }
    # AWS restricts length and characters of ELB names
    elb_a_names = elb_names.map{ |name| create_elb(name) }
    instance_ids.zip(elb_names).each do |instance_id, elb_name|
      register_instance_with_elb(instance_id, elb_name)
    end
    # TODO: Exercise this.
    [name, "demo.#{name}"].map do |name|
      name.downcase # Otherwise there are discrepancies between DNS and the API.
    end.zip(elb_a_names).each do |domain_name, elb_target_name|
      request_create_dns_cname_record(zone_id, domain_name, elb_target_name)
    end
    # TODO: Confirm DNS update.
  end
  
end
