require_relative 'dns_wrapper'
require_relative 'ec2_wrapper'
require_relative 'elb_wrapper'

class AwsWrapper
  include DnsWrapper
  include Ec2Wrapper
  include ElbWrapper
  
  def initialize(log_level = :debug)
    @log_level = log_level
  end
  
  def client_config
    {
      logger: LOGGER, 
      log_level: @log_level,
      # Optional log_formatter for more information:
      #log_formatter: Aws::Log::Formatter.new("REQUEST: :http_request_body\nRESPONSE: :http_response_body")
    }
  end
end
