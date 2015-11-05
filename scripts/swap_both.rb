require_relative '../lib/eip_dns_swapper'

if ARGV.count != 1
  fail 'USAGE: Provide the name of the live server which should be switched with demo.'
end

name = ARGV.shift
zone_id = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones:

EipDnsSwapper.new.swap(name, zone_id)