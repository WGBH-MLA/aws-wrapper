require_relative 'aws_wrapper'

class EipDnsSwapper < AwsWrapper
  def swap(base_name, zone_id)
    live_domain_name = base_name
    demo_domain_name = "demo.#{live_domain_name}"
    
    eip_ip = lookup_dns(zone_id, live_domain_name)
    demo_ip = lookup_dns(zone_id, demo_domain_name)
    fail("Live and demo are both #{demo_ip}") if eip_ip == demo_ip

    live_instance_id = lookup_eip(eip_ip).instance_id

    demo_instance = lookup_ip(demo_ip)

    LOGGER.info("About to assign EIP #{eip_ip} to former demo instance (#{demo_instance.instance_id})...")
    assign_eip(eip_ip, demo_instance)
    LOGGER.info("ASSIGNED EIP #{eip_ip} to #{lookup_eip(eip_ip).instance_id}")

    # At this point the live_instance object is out of date:
    # The object's public_ip_address is actually still the EIP.
    # So, look it up again:

    former_live_instance = nil # For scope
    begin
      sleep WAIT_INTERVAL
      former_live_instance = lookup_instance(live_instance_id)
      LOGGER.info("Instance #{live_instance_id} has ip: #{former_live_instance.public_ip_address}")
    end until former_live_instance && former_live_instance.public_ip_address

    LOGGER.info("About to assign DNS #{demo_domain_name} to former live instance IP (#{former_live_instance.public_ip_address})...")
    update_dns_a_record(zone_id, demo_domain_name, former_live_instance.public_ip_address)
    LOGGER.info("ASSIGNED DNS #{demo_domain_name} to #{lookup_dns(zone_id, demo_domain_name)}")
  end
end
