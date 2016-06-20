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
    fail ArgumentError, 'Missing required option :availability_zone' unless opts.key? :availability_zone
    @availability_zone = opts[:availability_zone]
    Aws.config[:region] = @availability_zone.gsub(/.$/, '') # Like 'us-east-1' : not sure if this is universal.
    @client_config = {
      logger: opts[:debug] ? LOGGER : nil,
      log_level: :debug, # Does not change the volume of logging, but instead sets the level of the messages.
      # Optional log_formatter for more information:
      # log_formatter: Aws::Log::Formatter.new("REQUEST: :http_request_body\nRESPONSE: :http_response_body")
    }
  end

  def dns_zone(name)
    name.sub(/^(.*\.)?([^.]+\.[^.]+)$/, '\2') + '.'
  end

  def sh_q(s)
    "'#{s.gsub('\'') { |_m| "'\\''" }}'"
  end

  def lookup_elb_and_instance(zone_name, name)
    # TODO: Should this be placed somewhere else?
    cname = lookup_cname(zone_name, name)
    elb = lookup_elb_by_dns_name(cname)
    elb_name = elb.load_balancer_name
    instance_ids = elb.instances.map(&:instance_id)
    if instance_ids.count != 1
      fail "Expected exactly 1 instance under '#{name}' (#{elb_name}), not: #{instance_ids}"
    end
    OpenStruct.new(elb_name: elb_name, instance_id: instance_ids.first)
  end
end
