require_relative 'dns_wrapper'
require_relative 'ec2_wrapper'
require_relative 'elb_wrapper'

class AwsWrapper
  include DnsWrapper
  include Ec2Wrapper
  include ElbWrapper
  
  attr_reader :client_config
  
  def initialize(opts = {})
    @client_config = {
      logger: opts[:debug] ? LOGGER : nil,
      log_level: :debug,
      # Optional log_formatter for more information:
      #log_formatter: Aws::Log::Formatter.new("REQUEST: :http_request_body\nRESPONSE: :http_response_body")
    }
  end
  
end
