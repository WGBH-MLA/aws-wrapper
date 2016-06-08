require 'aws-sdk'
require 'logger'
require 'set'
# Unless I require 'set' I get:
#   uninitialized constant Aws::Log::ParamFilter::Set (NameError)
#	  from /Users/chuck_mccallum/.rvm/gems/ruby-2.0.0-p481/gems/aws-sdk-core-2.1.23/lib/aws-sdk-core/log/formatter.rb:89:in `new'
# Was not able to make a minimal reproducer.

module BaseWrapper
  LOGGER = Logger.new($stderr, 'daily')
  LOGGER.formatter = proc do |severity, datetime, _progname, msg|
    "#{severity} [#{datetime.strftime('%Y-%m-%d %H:%M:%S')}]: #{msg}\n"
  end

  WAIT_INTERVAL = 5
  WAIT_ATTEMPTS = 50

  def wait_until
    1.step do |try|
      break if yield(try)
      fail('Giving up') if try >= WAIT_ATTEMPTS
      sleep(WAIT_INTERVAL)
    end
  end
end
