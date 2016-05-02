require_relative 'aws_wrapper'
require_relative 'lister'

# rubocop:disable Style/RescueModifier
class Destroyer < AwsWrapper
  def destroy(name, unsafe=false)
    if unsafe
      unsafe_destroy(name)
    else
      safe_destroy(name)
    end
  end

  private

  # We want to do as much cleaning as possible, hence the "rescue"s.

  def safe_destroy(name)
    # More conservative: Create a list of related resources to delete.
    # The downside is that if a root resource has already been deleted,
    # (like a DNS record) we won't find the formerly dependent records.

    flat_list = Lister.new(debug: @debug, availability_zone: @availability_zone)
                .list(name, true)

    flat_list[:groups].each do |group_name|
      delete_group_policy(group_name) rescue LOGGER.warn("Error deleting policy: #{$!} at #{$@}")
      LOGGER.info("Deleted policy #{group_name}")
      delete_group(group_name) rescue LOGGER.warn("Error deleting group: #{$!} at #{$@}")
      LOGGER.info("Deleted group #{group_name}")
    end
    flat_list.delete(:groups)

    flat_list[:key_names].each do |key_name|
      delete_key(key_name) rescue LOGGER.warn("Error deleting PK: #{$!} at #{$@}")
      LOGGER.info("Deleted PK #{key_name}")
    end
    flat_list.delete(:key_names)

    terminate_instances_by_id(flat_list[:instance_ids]) rescue LOGGER.warn("Error terminating EC2 instances: #{$!} at #{$@}")
    LOGGER.info("Terminated EC2 instances #{flat_list[:instance_ids]}")
    flat_list.delete(:instance_ids)
    flat_list.delete(:volume_ids) # Volumes are set to disappear with their instance.

    delete_dns_cname_records(dns_zone(name), flat_list[:cnames]) rescue LOGGER.warn("Error deleting CNAMEs: #{$!} at #{$@}")
    LOGGER.info("Deleted CNAMEs #{flat_list[:cnames]}")
    flat_list.delete(:cnames)

    flat_list.keys.tap do |forgot|
      fail("Still need to clean up #{forgot}") unless forgot.empty?
    end
  end

  def unsafe_destroy(name)
    # Delete resources based on name conventions.
    # If names are reused, this can end up deleting resources
    # which are not actually related.

    delete_key(name) rescue LOGGER.warn("Error deleting PK: #{$!} at #{$@}")
    LOGGER.info('Deleted PK')

    delete_group_policy(name) rescue LOGGER.warn("Error deleting policy: #{$!} at #{$@}")
    LOGGER.info('Deleted policy')

    delete_group(name) rescue LOGGER.warn("Error deleting group: #{$!} at #{$@}")
    LOGGER.info('Deleted group')

    terminate_instances_by_key(name) rescue LOGGER.warn("Error terminating EC2 instances: #{$!} at #{$@}")
    LOGGER.info('Terminated EC2 instances')

    elb_names(name).each do |elb|
      delete_elb(elb) rescue LOGGER.warn("Error deleting ELB: #{$!} at #{$@}")
    end
    LOGGER.info('Deleted ELB')

    delete_dns_cname_records(dns_zone(name), cname_pair(name)) rescue LOGGER.warn("Error deleting CNAME: #{$!} at #{$@}")
    LOGGER.info('Deleted CNAMEs')
  end
end
