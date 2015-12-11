require_relative 'aws_wrapper'
require_relative 'ssh_opter'
require 'open3'

class Sudoer < AwsWrapper
  
  def sudo(zone_id, name, command)
    ssh_opts = SshOpter.new(availability_zone: @availability_zone).ssh_opts(zone_id, name)
    ssh_command = "ssh #{ssh_opts} -t -t 'sudo sh -c \"#{command}\"'" # TODO: escaping
    # With no "-t": 
    #   "sudo: sorry, you must have a tty to run sudo"
    # One "-t" is sufficient when running directly from the shell, but inside a script:
    #   "Pseudo-terminal will not be allocated because stdin is not a terminal."
    # ... so you need "-t -t"
    1.step do |try|
      LOGGER.info("try #{try}: #{ssh_command}")
      Open3.popen2e(ssh_command) do |_input, output, thread|
        output.each do |line|
          LOGGER.info("#{name}: #{line.strip}")
        end
        break if thread.value.success?
        LOGGER.warn("ssh was not successful: #{thread.value}")
      end
      fail('Giving up') if try >= WAIT_ATTEMPTS
      sleep(WAIT_INTERVAL)
    end
  end
  
end
