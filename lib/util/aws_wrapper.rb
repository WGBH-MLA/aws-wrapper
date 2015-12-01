require_relative '../core/dns_wrapper'
require_relative '../core/ec2_wrapper'
require_relative '../core/elb_wrapper'
require_relative '../core/iam_wrapper'

class AwsWrapper
  include DnsWrapper
  include Ec2Wrapper
  include ElbWrapper
  include IamWrapper
  
  attr_reader :client_config
  
  def initialize(opts = {})
    @client_config = {
      logger: opts[:debug] ? LOGGER : nil,
      log_level: :debug, # Does not change the volume of logging, but instead sets the level of the messages.
      # Optional log_formatter for more information:
      #log_formatter: Aws::Log::Formatter.new("REQUEST: :http_request_body\nRESPONSE: :http_response_body")
    }
  end
  
end
