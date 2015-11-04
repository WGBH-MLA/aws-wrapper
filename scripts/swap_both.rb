require_relative '../lib/aws_wrapper'
require 'resolv'

ZONE_ID = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones:

if ARGV.empty?
  puts 'USAGE: Provide the name of the live server which should be switched with demo.'
  exit
end

live_domain_name = ARGV.shift
demo_domain_name = "demo.#{live_domain_name}"

AwsWrapper.new.tap do |aws|
  eip_ip = aws.lookup_dns(live_domain_name)
  demo_ip = aws.lookup_dns(demo_domain_name)
  fail("Live and demo are both #{demo_ip}") if eip_ip == demo_ip

  live_instance_id = aws.lookup_eip(eip_ip).instance_id

  demo_instance = aws.lookup_ip(demo_ip)

  aws.class::LOGGER.info("About to assign EIP #{eip_ip} to former demo instance (#{demo_instance.instance_id})...")
  aws.assign_eip(eip_ip, demo_instance)
  aws.class::LOGGER.info("ASSIGNED EIP #{eip_ip} to #{aws.lookup_eip(eip_ip).instance_id}")
  
  # At this point the live_instance object is out of date:
  # The object's public_ip_address is actually still the EIP.
  # So, look it up again:
  
  former_live_instance = nil # For scope
  begin
    sleep aws.class::WAIT_INTERVAL
    former_live_instance = aws.lookup_instance(live_instance_id)
    aws.class::LOGGER.info("Instance #{live_instance_id} has ip: #{former_live_instance.public_ip_address}")
  end until former_live_instance && former_live_instance.public_ip_address
  
  aws.class::LOGGER.info("About to assign DNS #{demo_domain_name} to former live instance IP (#{former_live_instance.public_ip_address})...")
  aws.update_dns_a_record(ZONE_ID, demo_domain_name, former_live_instance.public_ip_address)
  aws.class::LOGGER.info("ASSIGNED DNS #{demo_domain_name} to #{aws.lookup_dns(demo_domain_name)}")
end