require_relative '../lib/aws_wrapper'
require 'resolv'

ZONE_ID = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones:
AWS_WRAPPER = AwsWrapper.instance

if ARGV.empty?
  puts 'USAGE: Provide the name of the live server which should be switched with demo.'
  exit
end

live_domain_name = ARGV.shift
demo_domain_name = "demo.#{live_domain_name}"

def lookup(domain_name)
  aws_ip = AWS_WRAPPER.lookup_dns_a_record(ZONE_ID, domain_name)
  dns_ip = Resolv.getaddress(domain_name)
  fail("Discrepancy for #{domain_name}: AWS=#{aws_ip} but DNS=#{dns_ip}") unless dns_ip == aws_ip
  dns_ip
end

eip_ip = lookup(live_domain_name)
demo_ip = lookup(demo_domain_name)
fail("Live and demo are both #{demo_ip}") if eip_ip == demo_ip

live_instance_id = AWS_WRAPPER.lookup_eip(eip_ip).instance_id
live_instance = AWS_WRAPPER.lookup_instance(live_instance_id)

demo_instance = AWS_WRAPPER.lookup_ip(demo_ip)

AWS_WRAPPER.logger.info("About to assign EIP (#{eip_ip}) to former demo instance...")
AWS_WRAPPER.assign_eip(eip_ip, demo_instance)
AWS_WRAPPER.logger.info("About to assign #{demo_domain_name} to former live instance...")
AWS_WRAPPER.update_dns_a_record(ZONE_ID, demo_domain_name, live_instance.public_ip_address)