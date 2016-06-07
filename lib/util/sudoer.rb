require_relative 'aws_wrapper'
require_relative 'ssh_opter'
require 'open3'

class Sudoer < AwsWrapper
  def sudo(name, command, is_sudo=true) # TODO: rename method, use named params.
    command = 'sudo sh -c ' + sh_q(command) if is_sudo
    ssh(ssh_opts(name), command)
  end

  def sudo_by_ip(name, command, ip)
    command = 'sudo sh -c ' + sh_q(command)
    ssh(ssh_opts(name, ip), command)
  end

  private

  def ssh_opts(name, ip=nil)
    SshOpter.new(availability_zone: @availability_zone).ssh_opts(name, ip)
  end

  def ssh(ssh_opts, command)
    ssh_command = "ssh #{ssh_opts} -t -t " + sh_q(command)
    # With no "-t" (if the system you're connecting to is fussy):
    #   "sudo: sorry, you must have a tty to run sudo"
    # One "-t" is sufficient when running directly from the shell, but inside a script:
    #   "Pseudo-terminal will not be allocated because stdin is not a terminal."
    # ... so you need "-t -t"
    catch :success do
      wait_until do |try|
        LOGGER.info("try #{try}: #{ssh_command}")
        Open3.popen2e(ssh_command) do |_input, output, thread|
          output.each do |line|
            # LOGGER.info("#{name}: #{line.strip}")
            # TODO: name is no longer available here, but it probably should be?
            LOGGER.info("#{line.strip}")
          end
          throw :success if thread.value.success?
          LOGGER.warn("ssh was not successful: #{thread.value}")
          LOGGER.warn('(But new servers need time to warm up. Will retry.)')
        end
      end
    end
  end
end
