require_relative 'aws_wrapper'

class SshOpter < AwsWrapper
  def ssh_opts(name, ip=nil)
    ssh_delete_identities = 'ssh-add -D'
    system(ssh_delete_identities) || fail("Failed '#{ssh_delete_identities}'")
    LOGGER.info("Deleted old identities from SSH agent: #{ssh_delete_identities}")

    key_path = key_path(name.gsub(/^demo\./, ''))
    ssh_add = "ssh-add #{key_path}"
    system(ssh_add) || fail("Failed '#{ssh_add}'")
    LOGGER.info("Added #{key_path} to SSH agent")
    # Add key to SSH agent, and then use the agent ("-A") rather than
    # the key on connect. (Starting with SSH agent is necessary for
    # agent forwarding between blue and green to work: "-i" is not enough.)
    # Turn off HostKeyChecking so this can be non-interactive.

    ip ||= lookup_ip(name)
    args = "-A -o StrictHostKeyChecking=no ec2-user@#{ip}"
    LOGGER.info(args)
    args
  end

  def lookup_ip(name)
    zone_name = dns_zone(name)
    points_to = lookup_cname(zone_name, name)
    instance_ids = lookup_elb_by_dns_name(points_to).instances.map(&:instance_id)
    fail("Multiple instances behind ELB: #{instance_ids}") if instance_ids.count > 1
    lookup_instance(instance_ids.first).public_ip_address
  end

  def ips_by_tag(name_tag)
    lookup_public_ips_by_name(name_tag)
  end

  def ip_by_dns(name)
    lookup_ip(name)
  end
end
