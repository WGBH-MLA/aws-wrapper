require_relative 'sudoer'
require_relative 'swapper'
require_relative 'aws_wrapper'

class Builder < AwsWrapper
  DEVICE_PATH = '/dev/sdb'

  def build(config)
    zone_id = config[:zone_id]
    name = config[:name]
    size_in_gb = config[:size_in_gb]
    skip_updates = config[:skip_updates]
    mount_path = config[:mount_path]
    instance_type = config[:instance_type]
    
    create_key(name)
    LOGGER.info("Created PK for #{name}")

    create_group(name)
    add_current_user_to_group(name)
    LOGGER.info("Created group #{name}, and added current user")

    instance_ids = start_instances(2, name, instance_type).map(&:instance_id)
    LOGGER.info("Started 2 EC2 instances #{instance_ids}")

    instance_ids.each do |instance_id|
      create_and_attach_volume(instance_id, DEVICE_PATH, size_in_gb)
    end
    LOGGER.info('Attached EBS volume to each instance')

    elb_names = elb_names(name)
    elb_a_names = elb_names.map { |name| create_elb(name) }
    instance_ids.zip(elb_names).each do |instance_id, elb_name|
      register_instance_with_elb(instance_id, elb_name)
    end
    LOGGER.info('Created load balancers and registered instances')

    # Maybe this would be better managed than inline?
    # But then that would be another thing to clean up.
    put_group_policy(name,       'Effect' => 'Allow',
                                 'Action' => 'elasticloadbalancing:*', # TODO: tighten
                                 'Resource' => elb_names.map { |elb_name| elb_arn(elb_name) })
    LOGGER.info('Create group policy for ELB')

    name_target_pairs = cname_pair(name).zip(elb_a_names)
    create_dns_cname_records(zone_id, name_target_pairs)
    LOGGER.info('Created CNAMEs')

    Sudoer.new(debug: @debug, availability_zone: @availability_zone).tap do |sudoer|
      commands = [
        "mkfs -t ext4 #{DEVICE_PATH}",
        "mkdir #{mount_path}",
        "mount #{DEVICE_PATH} #{mount_path}",
        "chown ec2-user #{mount_path}"
      ]
      # Agent forwarding allows one machine to connect directly to the other,
      # relying on the local private key.
      one_liner = '$_="AllowAgentForwarding yes\n" if /AllowAgentForwarding/'
      commands.push('ruby -i.back -pne ' + sh_q(one_liner) + ' /etc/ssh/sshd_config')
      commands.push('yum update --assumeyes') unless skip_updates # Takes a long time
      commands_joined = commands.join (' && ')
      sudoer.sudo(zone_id, "demo.#{name}", commands_joined)
      LOGGER.info('Swap instances and do it again.')
      Swapper.new(debug: @debug, availability_zone: @availability_zone).swap(zone_id, name, mount_path)
      sudoer.sudo(zone_id, "demo.#{name}", commands_joined)
    end
    LOGGER.info('Instances are up / EBS volumes are mounted.')
  end
end
