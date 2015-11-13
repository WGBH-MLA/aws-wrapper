require_relative 'dns_wrapper'
require_relative 'ec2_wrapper'
require_relative 'elb_wrapper'

class AwsWrapper
  include DnsWrapper
  include Ec2Wrapper
  include ElbWrapper
end
