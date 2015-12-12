require_relative 'sudoer'
require_relative 'elb_swapper'
require_relative 'aws_wrapper'

class Ec2ElbStarter < AwsWrapper
  
  DEVICE_PATH = '/dev/sdb'
  MOUNT_PATH = '/mnt/ebs'
  
  def start(zone_id, name, size_in_gb, skip_updates)
    create_key(name)
    LOGGER.info("Created PK for #{name}")
    
    create_group(name)
    add_current_user_to_group(name)
    LOGGER.info("Created group #{name}, and added current user")
    
    instance_ids = start_instances(2, name).map(&:instance_id)
    LOGGER.info("Started 2 EC2 instances #{instance_ids}")
    
    instance_ids.each do |instance_id|
      create_and_attach_volume(instance_id, DEVICE_PATH, size_in_gb)
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
    })
    LOGGER.info("Create group policy for ELB")
    
    name_target_pairs = cname_pair(name).zip(elb_a_names)
    create_dns_cname_records(zone_id, name_target_pairs)
    LOGGER.info("Created CNAMEs")
    
    Sudoer.new(debug: @debug, availability_zone: @availability_zone).tap do |sudoer|
      commands = [
        "mkfs -t ext4 #{DEVICE_PATH}",
        "mkdir #{MOUNT_PATH}",
        "mount #{DEVICE_PATH} #{MOUNT_PATH}",
        "chown ec2-user #{MOUNT_PATH}",
        # Agent forwarding allows one machine to connect directly to the other,
        # relying on the local private key.
        "ruby -i.back -pne '\''\'\'''\''$_=%qq{AllowAgentForwarding yes\n} if /AllowAgentForwarding/'\''\'\'''\'' /etc/ssh/sshd_config"
        # TODO: Util function for escaping!!!!
      ]
      commands.push('yum update --assumeyes') unless skip_updates # Takes a long time
      commands_joined = commands.join (' && ')
      sudoer.sudo(zone_id, "demo.#{name}", commands_joined)
      LOGGER.info("Swap instances and do it again.")
      ElbSwapper.new(debug: @debug, availability_zone: @availability_zone).swap(zone_id, name)
      sudoer.sudo(zone_id, "demo.#{name}", commands_joined)
    end
    LOGGER.info("Instances are up / EBS volumes are mounted.")
  end
  
end
