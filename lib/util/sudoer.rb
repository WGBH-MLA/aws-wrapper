require_relative 'aws_wrapper'
require_relative 'ssh_opter'
require 'open3'

class Sudoer < AwsWrapper

  def sudo(zone_id, name, command, sudo=true) # TODO: rename method, use named params.
    command = 'sudo sh -c ' + sh_q(command) if sudo
    ssh_opts = SshOpter.new(availability_zone: @availability_zone).ssh_opts(zone_id, name)
    ssh_command = "ssh #{ssh_opts} -t -t " + sh_q(command)
    # With no "-t" (if the system you're connecting to is fussy):
    #   "sudo: sorry, you must have a tty to run sudo"
    # One "-t" is sufficient when running directly from the shell, but inside a script:
    #   "Pseudo-terminal will not be allocated because stdin is not a terminal."
    # ... so you need "-t -t"
    catch :success do
      1.step do |try|
        LOGGER.info("try #{try}: #{ssh_command}")
        Open3.popen2e(ssh_command) do |_input, output, thread|
          output.each do |line|
            LOGGER.info("#{name}: #{line.strip}")
          end
          throw :success if thread.value.success?
          LOGGER.warn("ssh was not successful: #{thread.value}")
          LOGGER.warn('(But new servers need time to warm up. Will retry.)')
        end
        fail('Giving up') if try >= WAIT_ATTEMPTS
        sleep(WAIT_INTERVAL)
      end
    end
  end

  # def sudo_by_ip(zone_id, ip, command, sudo=true)
  def sudo_by_ip(zone_id, name, command, ip=nil)
    command = 'sudo sh -c ' + sh_q(command)
    ssh_opts = SshOpter.new(availability_zone: @availability_zone).ssh_opts(zone_id, name, ip)
    ssh_command = "ssh #{ssh_opts} -t -t " + sh_q(command)
    # With no "-t" (if the system you're connecting to is fussy):
    #   "sudo: sorry, you must have a tty to run sudo"
    # One "-t" is sufficient when running directly from the shell, but inside a script:
    #   "Pseudo-terminal will not be allocated because stdin is not a terminal."
    # ... so you need "-t -t"
    catch :success do
      1.step do |try|
        LOGGER.info("try #{try}: #{ssh_command}")
        Open3.popen2e(ssh_command) do |_input, output, thread|
          output.each do |line|
            LOGGER.info("#{ip}: #{line.strip}")
          end
          throw :success if thread.value.success?
          LOGGER.warn("ssh was not successful: #{thread.value}")
          LOGGER.warn('(But new servers need time to warm up. Will retry.)')
        end
        fail('Giving up') if try >= WAIT_ATTEMPTS
        sleep(WAIT_INTERVAL)
      end
    end
  end
end
