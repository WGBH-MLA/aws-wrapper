require_relative '../lib/aws_wrapper'

zone_id = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones:
domain_name = ARGV.shift
new_ip = ARGV.shift

# EIP (live): 107.21.231.21
# EC2 (demo): 54.157.204.80

AwsWrapper.instance.tap do |aws|
  aws.update_dns_a_record(zone_id, domain_name, new_ip)
end