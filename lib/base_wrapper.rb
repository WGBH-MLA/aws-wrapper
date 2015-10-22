require 'aws-sdk'
require 'logger'
require 'set'
# Unless I require 'set' I get:
#   uninitialized constant Aws::Log::ParamFilter::Set (NameError)
#	  from /Users/chuck_mccallum/.rvm/gems/ruby-2.0.0-p481/gems/aws-sdk-core-2.1.23/lib/aws-sdk-core/log/formatter.rb:89:in `new'
# Was not able to make a minimal reproducer.

module BaseWrapper
  
  attr_reader :logger
  
  Aws.config[:region] = 'us-east-1' # One-time configuration at module load.
  
  def initialize
    log_file_name = $stdout
    @logger = Logger.new(log_file_name, 'daily')
    @logger.formatter = proc do |severity, datetime, _progname, msg|
      "#{severity} [#{datetime.strftime('%Y-%m-%d %H:%M:%S')}]: #{msg}\n"
    end
    @client_config = {
      logger: @logger, 
      log_level: :debug,
      # Optional log_formatter for more information:
      log_formatter: Aws::Log::Formatter.new(':http_response_body')
    }
  end
  
  def config_wait(w)
    w.interval = 5
    w.max_attempts = 100
    w.before_wait do |n, last_response|
      # TODO: If this is only for EC2s, it should be moved there.
      status = last_response.data.reservations.map { |r| 
        r.instances.map { |i| 
          "#{i.instance_id}: #{i.state.name}"
        }
      }.flatten
      logger.info("#{n}: Waiting... #{status}")
    end
  end
  
end