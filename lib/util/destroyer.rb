require_relative 'aws_wrapper'

class Destroyer < AwsWrapper
  def destroy(zone_id, name)
    # We want to do as much cleaning as possible, hence the "rescue"s.

    begin
      delete_key(name)
    rescue
      LOGGER.warn("Error deleting PK: #{$ERROR_INFO} at #{$ERROR_POSITION}")
    end
    LOGGER.info('Deleted PK')

    begin
      delete_group_policy(name)
    rescue
      LOGGER.warn("Error deleting policy: #{$ERROR_INFO} at #{$ERROR_POSITION}")
    end
    LOGGER.info('Deleted policy')

    begin
      delete_group(name)
    rescue
      LOGGER.warn("Error deleting group: #{$ERROR_INFO} at #{$ERROR_POSITION}")
    end
    LOGGER.info('Deleted group')

    begin
      terminate_instances(name)
    rescue
      LOGGER.warn("Error terminating EC2 instances: #{$ERROR_INFO} at #{$ERROR_POSITION}")
    end
    LOGGER.info('Terminated EC2 instances')

    elb_names(name).each do |elb|
      begin
        delete_elb(elb)
      rescue
        LOGGER.warn("Error deleting ELB: #{$ERROR_INFO} at #{$ERROR_POSITION}")
      end
    end
    LOGGER.info('Deleted ELB')

    begin
      delete_dns_cname_records(zone_id, cname_pair(name))
    rescue
      LOGGER.warn("Error deleting CNAME: #{$ERROR_INFO} at #{$ERROR_POSITION}")
    end
    LOGGER.info('Deleted CNAMEs')
  end
end
