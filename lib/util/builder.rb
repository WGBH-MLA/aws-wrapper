require_relative 'swapper'
require_relative 'aws_wrapper'

class Builder < AwsWrapper
  def build(config)
    zone_id = config[:zone_id]
    name = config[:name]
    instance_type = config[:instance_type]
    image_id = config[:image_id]

    max_length = 30 # 32 is max for ELB names, and we append "-a" or "-b".
    fail("Name '#{name}' must not be longer than #{max_length} characters") if name.length > max_length

    create_key(name)
    LOGGER.info("Created PK for #{name}")

    create_group(name)
    add_current_user_to_group(name)
    LOGGER.info("Created group #{name}, and added current user")

    instance_ids = start_instances(2, name, instance_type, image_id).map(&:instance_id)
    LOGGER.info("Started 2 EC2 instances #{instance_ids}")
  end

  def setup_load_balancer(config)
    zone_id = config[:zone_id]
    name = config[:name]

    elb_names = elb_names(name)
    elb_a_names = elb_names.map { |name| create_elb(name) }
    lookup_instance_ids_by_name(name).zip(elb_names).each do |instance_id, elb_name|
      register_instance_with_elb(instance_id, elb_name)
    end
    LOGGER.info('Created load balancers and registered instances')

    # Maybe this would be better managed than inline?
    # But then that would be another thing to clean up.
    put_group_policy(name,
                     'Effect' => 'Allow',
                     'Action' => 'elasticloadbalancing:*', # TODO: tighten
                     'Resource' => elb_names.map { |elb_name| elb_arn(elb_name) })
    LOGGER.info('Create group policy for ELB')

    name_target_pairs = cname_pair(name).zip(elb_a_names)
    create_dns_cname_records(zone_id, name_target_pairs)
    LOGGER.info('Created CNAMEs')
  end
end
