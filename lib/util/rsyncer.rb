require_relative 'aws_wrapper'
require_relative 'ssh_opter'
require_relative 'sudoer'
require 'ostruct'

class Rsyncer < AwsWrapper
  def rsync(zone_id, live_name, mount_path)
    demo_name = 'demo.' + live_name

    live_ip = SshOpter.new(debug: @debug, availability_zone: @availability_zone).lookup_ip(zone_id, live_name)
    rsync_command = "rsync -ave 'ssh -A -o StrictHostKeyChecking=no -l ec2-user' --exclude=lost+found ec2-user@#{live_ip}:#{mount_path}/ #{mount_path}/"
    # -a: archive, -v: verbose, -e: for SSH agent forwarding.
    if_exists_rsync_command = "if [ -e #{mount_path} ]; then #{rsync_command}; fi"
    # On the first swap the directory does not yet exist, and user does not have privs to create.
    LOGGER.info("Will login to demo, and rsync #{mount_path} from live to demo using SSH agent forwarding, if target exists.")
    Sudoer.new(debug: @debug, availability_zone: @availability_zone).sudo(zone_id, demo_name, if_exists_rsync_command, false)
  end
end
