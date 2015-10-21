require 'aws-sdk'
require 'logger'

module AwsWrapper
  
  attr_reader :logger
  
  Aws.config[:region] = 'us-east-1' # One-time configuration at module load.
  
  def initialize
    log_file_name = $stdout
    @logger = Logger.new(log_file_name, 'daily')
    @logger.formatter = proc do |severity, datetime, _progname, msg|
      "#{severity} [#{datetime.strftime('%Y-%m-%d %H:%M:%S')}]: #{msg}\n"
    end
  end
  
  def config_wait(w)
    w.interval = 5
    w.max_attempts = 100
    w.before_wait do |n, last_response|
      status = last_response.data.reservations.map { |r| 
        r.instances.map { |i| 
          "#{i.instance_id}: #{i.state.name}"
        }
      }.flatten
      logger.info("#{n}: Waiting... #{status}")
    end
  end
  
end