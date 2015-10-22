require 'singleton'
require_relative 'dns_manager'
require_relative 'ec2_manager'

class AwsWrapper
  include DnsManager
  include Ec2Manager
  include Singleton
  
  def initialize
    super
  end
end
