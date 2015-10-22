require_relative 'base_manager'

module DnsManager
  include BaseManager
  
  def initialize
    super
    @dns_client = Aws::Route53::Client.new(
      logger: @logger, 
      log_level: :debug,
      #log_formatter: Aws::Log::Formatter.new(':http_response_body')
    )
  end
  
end
