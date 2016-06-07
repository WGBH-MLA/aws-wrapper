require_relative 'aws_wrapper'
require 'ostruct'

class Swapper < AwsWrapper
  def swap(live_name)
    zone_name = dns_zone(live_name)
    demo_name = 'demo.' + live_name

    live = lookup_elb_and_instance(zone_name, live_name)
    LOGGER.info("live: #{live.elb_name} / #{live.instance_id}")
    demo = lookup_elb_and_instance(zone_name, demo_name)
    LOGGER.info("demo: #{demo.elb_name} / #{demo.instance_id}")

    register_instance_with_elb(demo.instance_id, live.elb_name)
    register_instance_with_elb(live.instance_id, demo.elb_name)
    LOGGER.info('Half swapped: Registered both instances to both ELBs')

    deregister_instance_from_elb(demo.instance_id, demo.elb_name)
    deregister_instance_from_elb(live.instance_id, live.elb_name)
    LOGGER.info('Swap complete: De-registered both instances from original ELBs')

    stop_instances_by_ids([live.instance_id])
    LOGGER.info('Stopping former live instance')
  end

  private

  def lookup_elb_and_instance(zone_name, name)
    cname = lookup_cname(zone_name, name)
    elb = lookup_elb_by_dns_name(cname)
    elb_name = elb.load_balancer_name
    instance_ids = elb.instances.map(&:instance_id)
    if instance_ids.count != 1
      fail "Expected exactly 1 instance under '#{name}' (#{elb_name}), not: #{instance_ids}"
    end
    OpenStruct.new(elb_name: elb_name, instance_id: instance_ids.first)
  end
end
