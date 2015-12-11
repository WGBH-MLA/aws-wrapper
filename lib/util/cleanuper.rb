require_relative 'aws_wrapper'

class Cleanuper < AwsWrapper
  def cleanup(zone_id, name)
    # We want to do as much cleaning as possible, hence the "rescue"s.
    
    delete_key(name) rescue LOGGER.warn("Error deleting PK: #{$!} at #{$@}")
    LOGGER.info('Deleted PK')
    
    delete_group_policy(name) rescue LOGGER.warn("Error deleting policy: #{$!} at #{$@}")
    LOGGER.info('Deleted policy')
    
    delete_group(name) rescue LOGGER.warn("Error deleting group: #{$!} at #{$@}")
    LOGGER.info('Deleted group')
    
    terminate_instances(name) rescue LOGGER.warn("Error terminating EC2 instances: #{$!} at #{$@}")
    LOGGER.info('Terminated EC2 instances')
    
    elb_names(name).each do |elb|
      delete_elb(elb) rescue LOGGER.warn("Error deleting ELB: #{$!} at #{$@}")
    end
    LOGGER.info('Deleted ELB')
    
    delete_dns_cname_records(zone_id, cname_pair(name)) rescue LOGGER.warn("Error deleting CNAME: #{$!} at #{$@}")
    LOGGER.info('Deleted CNAMEs')
  end
end
