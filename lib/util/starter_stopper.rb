require 'aws_wrapper'

class StarterStopper < AwsWrapper
  def start(name)
    start_instances_by_id([lookup_instance_id_by_dns_name(name)])
  end

  def stop(name)
    stop_instances_by_id([lookup_instance_id_by_dns_name(name)])
  end

  private

  def lookup_instance_id_by_dns_name(name)
    zone_name = dns_zone(name)
    elb_instance = lookup_elb_and_instance(zone_name, name)
    elb_instance.instance_id
  end
end
