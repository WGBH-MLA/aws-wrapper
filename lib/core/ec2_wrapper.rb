require_relative 'base_wrapper'

module Ec2Wrapper
  include BaseWrapper

  def create_tag(id, key, value)
    ec2_client.create_tags(
      resources: [id], # required
      tags: [ # required
        {
          key: key,
          value: value
        }
      ])
  end

  def key_path(name)
    # We can't rely on "~" expanding.
    "#{Dir.home}/.ssh/#{name}.pem"
  end

  def create_key(name, save_key=true)
    key_path = key_path(name)
    fail("PK already exists: #{key_path}") if File.exist?(key_path)
    key = ec2_client.create_key_pair(key_name: name)
    if save_key # So tests can avoid writing to filesystem
      File.write(key_path, key.key_material)
      FileUtils.chmod('u=wr,go=', key_path)
      LOGGER.info("Created key pair and stored private key at #{key_path}. Fingerprint: #{key.key_fingerprint}")
    end
    key
  end

  def delete_key(name)
    key_path(name).tap do |key_path|
      begin
        File.delete(key_path)
      rescue
        LOGGER.warn("Error deleting #{key_path}: #{$ERROR_INFO} at #{$ERROR_POSITION}")
      end
    end
    ec2_client.delete_key_pair(key_name: name)
  end

  def start_instances(n, key_name, instance_type, image_id)
    response_run_instances = ec2_client.run_instances(
      placement: {
        availability_zone: availability_zone
      },
      image_id: image_id,
      min_count: n, # required
      max_count: n, # required
      key_name: key_name,
      instance_type: instance_type,
      monitoring: {
        enabled: false, # required
      },
      disable_api_termination: false,
      instance_initiated_shutdown_behavior: 'terminate', # accepts stop, terminate
    )
    instances = response_run_instances.instances

    ec2_client.wait_until(:instance_running, instance_ids: instances.map(&:instance_id)) do |w|
      config_wait(w)
    end

    instances.map(&:instance_id).each do |instance_id|
      # 'Name' is special value which will display in the leftmost column of the console.
      create_tag(instance_id, 'Name', key_name)
    end

    instances
  end

  def terminate_instances_by_key(key_name)
    instance_ids = ec2_client.describe_instances(
      filters: [{
        name: 'key-name',
        values: [key_name]
      }]).reservations.map { |res| res.instances.map(&:instance_id) }.flatten
    ec2_client.terminate_instances(instance_ids: instance_ids)
  end

  def terminate_instances_by_id(instance_ids)
    ec2_client.terminate_instances(instance_ids: instance_ids)
  end

  def lookup_instance(instance_id)
    response_describe_instances = ec2_client.describe_instances(instance_ids: [instance_id])
    reservations = response_describe_instances.reservations
    fail("Expected one reservation on #{instance_id}, not #{reservations}") if reservations.count != 1
    instances = reservations[0].instances
    fail("Expected one instance on #{reservations[0]}, not #{instances}") if instances.count != 1
    instances[0]
  end

  def lookup_public_ips_by_name(name_tag)
    lookup_instances(name_tag).map(&:public_ip_address)
  end

  def lookup_instance_ids_by_name(name_tag)
    lookup_instances(name_tag).map(&:instance_id)
  end

  private

  def ec2_client
    @ec2_client ||= Aws::EC2::Client.new(client_config)
  end

  def lookup_instances(name_tag)
    response_describe_instances = ec2_client.describe_instances(filters: [
      { name: 'tag:Name', values: [name_tag] },
      { name: 'instance-state-name', values: %w(pending running) }
    ])
    reservations = response_describe_instances.reservations
    fail("Expected one reservation for tag:Name = #{name_tag}, not #{reservations}") if reservations.count != 1
    reservations[0].instances
  end

  def config_wait(w)
    w.interval = WAIT_INTERVAL
    w.max_attempts = WAIT_ATTEMPTS
    w.before_wait do |n, last_response|
      status = begin
                 last_response.data.reservations.map do |r|
                   r.instances.map do |i|
                     "#{i.instance_id}: #{i.state.name}"
                   end
                 end.flatten
               rescue
                 LOGGER.warn("Error reading EC2 reservations; will try again: #{$ERROR_INFO}")
               end
      LOGGER.info("try #{n}: EC2 instances not ready yet. #{status}")
    end
  end
end
