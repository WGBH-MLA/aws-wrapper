require_relative 'sudoer'
require_relative 'swapper'
require_relative 'aws_wrapper'

class Builder < AwsWrapper
  def build(config)
    zone_id = config[:zone_id]
    name = config[:name]
    size_in_gb = config[:size_in_gb]
    skip_updates = config[:skip_updates]
    device_name = config[:device_name]
    mount_path = config[:mount_path]
    instance_type = config[:instance_type]
    snapshot_id = config[:snapshot_id]
    image_id = config[:image_id]

    [name.length, 32].tap do |length, max|
      fail("Name must not be longer than #{max} characters: '#{name}' is #{length}") if length > max
    end

    create_key(name)
    LOGGER.info("Created PK for #{name}")

    create_group(name)
    add_current_user_to_group(name)
    LOGGER.info("Created group #{name}, and added current user")

    instance_ids = start_instances(2, name, instance_type, image_id).map(&:instance_id)
    LOGGER.info("Started 2 EC2 instances #{instance_ids}")

    instance_ids.each do |instance_id|
      create_and_attach_volume(name, instance_id, device_name, size_in_gb, snapshot_id)
    end
    LOGGER.info('Attached EBS volume to each instance')

    Sudoer.new(debug: @debug, availability_zone: @availability_zone).tap do |sudoer|
      commands = [
        "mkfs -t ext4 #{device_name}",
        "mkdir #{mount_path}",
        "mount #{device_name} #{mount_path}",
        "chown ec2-user #{mount_path}"
      ]
      # Agent forwarding allows one machine to connect directly to the other,
      # relying on the local private key.
      one_liner = '$_="AllowAgentForwarding yes\n" if /AllowAgentForwarding/'
      commands.push('ruby -i.back -pne ' + sh_q(one_liner) + ' /etc/ssh/sshd_config')
      commands.push('yum update --assumeyes') unless skip_updates # Takes a long time
      commands_joined = commands.join (' && ')

      instance_ids.each do |instance_id|
        ip = lookup_instance(instance_id).public_ip_address
        sudoer.sudo_by_ip(zone_id, name, commands_joined, ip)
      end

      # # LOGGER.info('Swap instances and do it again.')
      # Swapper.new(debug: @debug, availability_zone: @availability_zone).swap(zone_id, name, device_name)
      # sudoer.sudo_by_ip(zone_id, "demo.#{name}", commands_joined, ip)
    end
    LOGGER.info('Instances are up / EBS volumes are mounted.')
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
