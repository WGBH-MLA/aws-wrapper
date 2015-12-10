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
    LOGGER.info("About to: #{ssh_command}")
    Open3.popen2e(ssh_command) do |_input, output, _wait_thread|
      output.each do |line|
        LOGGER.info("#{name}: #{line.strip}")
      end
    end
  end
  
end
