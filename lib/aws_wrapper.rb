require_relative 'dns_wrapper'
require_relative 'ec2_wrapper'

class AwsWrapper
  include DnsWrapper
  include Ec2Wrapper
end
