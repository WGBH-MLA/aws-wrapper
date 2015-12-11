require_relative 'aws_wrapper'

class SshOpter < AwsWrapper
  def ssh_opts(zone_id, name)
    points_to = lookup_cname(zone_id, name)
    instance_ids = lookup_elb_by_dns_name(points_to).instances.map(&:instance_id)
    fail("Multiple instances behind ELB: #{instance_ids}") if instance_ids.count > 1
    ip = lookup_instance(instance_ids.first).public_ip_address
    # "~" was not expanding in backticks, so we lookup the homedir here.
    key_path = "#{Dir.home}/.ssh/#{name.gsub(/^demo\./,'')}.pem"
    "-i #{key_path} -o StrictHostKeyChecking=no ec2-user@#{ip}"
  end
end
