require_relative 'aws_wrapper'
require_relative 'ssh_opter'
require_relative 'sudoer'
require 'ostruct'

class Swapper < AwsWrapper
  def swap(zone_id, live_name)
    demo_name = 'demo.'+live_name
    
    live = lookup_elb_and_instance(zone_id, live_name)
    LOGGER.info("live: #{live.elb_name} / #{live.instance_id}")
    demo = lookup_elb_and_instance(zone_id, demo_name)
    LOGGER.info("demo: #{demo.elb_name} / #{demo.instance_id}")
    
    snapshot_id = create_snapshot(lookup_volume_id(demo.instance_id))
    LOGGER.info("Creating snapshot #{snapshot_id}. Process is slow and will continue in background.")
    
    register_instance_with_elb(demo.instance_id, live.elb_name)
    register_instance_with_elb(live.instance_id, demo.elb_name)
    LOGGER.info("Half swapped: Registered both instances to both ELBs")
    
    deregister_instance_from_elb(demo.instance_id, demo.elb_name)
    deregister_instance_from_elb(live.instance_id, live.elb_name)
    LOGGER.info("Swap complete: De-registered both instances from original ELBs")
    
    live_ip = SshOpter.new(debug: @debug, availability_zone: @availability_zone).lookup_ip(zone_id, live_name)
    rsync_command = "rsync -ave 'ssh -A -o StrictHostKeyChecking=no -l ec2-user' --exclude=lost+found ec2-user@#{live_ip}:/mnt/ebs/ /mnt/ebs/"
    # -a: archive, -v: verbose, -e: for SSH agent forwarding.
    if_exists_rsync_command = "if [ -e /mnt/ebs ]; then #{rsync_command}; fi"
    # On the first swap the directory does not yet exist, and user does not have privs to create.
    LOGGER.info("Will login to demo, and ssh /mnt/ebs from live to demo using SSH agent forwarding, if target exists.")
    Sudoer.new(debug: @debug, availability_zone: @availability_zone).sudo(zone_id, demo_name, if_exists_rsync_command, false)
  end
  
  def lookup_elb_and_instance(zone_id, name)
    cname = lookup_cname(zone_id, name)
    elb = lookup_elb_by_dns_name(cname)
    elb_name = elb.load_balancer_name
    instance_ids = elb.instances.map(&:instance_id)
    if instance_ids.count != 1
      fail "Expected exactly 1 instance under '#{name}' (#{elb_name}), not: #{instance_ids}"
    end
    OpenStruct.new(elb_name: elb_name, instance_id: instance_ids.first)
  end
  
end
