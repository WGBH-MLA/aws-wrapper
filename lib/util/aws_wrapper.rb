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
  attr_reader :availability_zone

  def initialize(opts={})
    raise ArgumentError, 'Missing required option :availability_zone' unless opts.key? :availability_zone
    @availability_zone = opts[:availability_zone]
    Aws.config[:region] = @availability_zone.gsub(/.$/, '') # Like 'us-east-1' : not sure if this is universal.
    @client_config = {
      logger: opts[:debug] ? LOGGER : nil,
      log_level: :debug, # Does not change the volume of logging, but instead sets the level of the messages.
      # Optional log_formatter for more information:
      # log_formatter: Aws::Log::Formatter.new("REQUEST: :http_request_body\nRESPONSE: :http_response_body")
    }
  end

  def sh_q(s)
    "'#{s.gsub('\'') { |_m| "'\\''" }}'"
  end
end
