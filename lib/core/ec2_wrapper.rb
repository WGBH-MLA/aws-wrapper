require_relative 'base_wrapper'

# rubocop:disable Metrics/ModuleLength
module Ec2Wrapper
  include BaseWrapper

  private

  def ec2_client
    @ec2_client ||= Aws::EC2::Client.new(client_config)
  end

  public

  def create_and_attach_volume(instance_id, device, size_in_gb)
    volume_id = ec2_client.create_volume(
      size: size_in_gb,
      # snapshot_id: "String",
      availability_zone: availability_zone, # required
      volume_type: 'standard', # accepts standard, io1, gp2
      # iops: 1,
      # encrypted: true,
      # kms_key_id: "String",
    ).volume_id
    1.step do |try|
      volume = ec2_client.describe_volumes(volume_ids: [volume_id]).volumes.find do |vol|
        vol.volume_id = volume_id
      end
      break if volume && volume.state == 'available'
      fail('Giving up') if try >= WAIT_ATTEMPTS
      LOGGER.info("try #{try}: Volume #{volume_id} not yet available")
      sleep(WAIT_INTERVAL)
    end
    ec2_client.attach_volume(
      volume_id: volume_id, # required
      instance_id: instance_id, # required
      device: device, # required: /dev/sdb thru /dev/sdp
    )
    ec2_client.modify_instance_attribute(
      instance_id: instance_id, # required
      attribute: 'blockDeviceMapping',
      block_device_mappings: [
        {
          device_name: device,
          ebs: {
            volume_id: volume_id,
            delete_on_termination: true
          }
        }
      ]
    )
  end

  def create_snapshot(volume_id, description, wait=false)
    snapshot_id = ec2_client.create_snapshot(volume_id: volume_id, description: description).snapshot_id
    1.step do |try|
      description = ec2_client.describe_snapshots(snapshot_ids: [snapshot_id]).snapshots[0]
      case description.state
      when 'pending'
        LOGGER.info("try #{try}: Snapshot #{snapshot_id} of volume #{volume_id} is still pending")
        sleep(WAIT_INTERVAL)
      when 'completed'
        break
      when 'error'
        fail("Snapshot #{snapshot_id} in error state: #{description.state_message}")
      else
        fail("Snapshot #{snapshot_id} in unexpected state: #{description.state} #{description.state_message}")
      end
    end if wait
    snapshot_id
  end

  def list_snapshots(volume_id)
    ec2_client.describe_snapshots(
      filters: [
        {
          name: 'volume-id',
          values: [volume_id]
        }
      ]
    ).snapshots
  end

  def key_path(name)
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

  def start_instances(n, key_name, instance_type)
    response_run_instances = ec2_client.run_instances(
      placement: {
        availability_zone: availability_zone
      },
      image_id: 'ami-cf1066aa', # PV EBS-Backed 64-bit / US East
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

    instances
  end

  def terminate_instances(key_name)
    instance_ids = ec2_client.describe_instances(filters: [{
                                                   name: 'key-name',
                                                   values: [key_name]
                                                 }]).reservations.map { |res| res.instances.map(&:instance_id) }.flatten
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

  def lookup_volume_id(instance_id, device_name)
    ids = lookup_volume_ids(instance_id, device_name)
    fail("Expected one volume_id on #{instance_id}, not #{ids}") if ids.count != 1
    ids[0]
  end

  def lookup_volume_ids(instance_id, device_name=nil)
    lookup_instance(instance_id).block_device_mappings
      .select { |mapping| !device_name || mapping.device_name == device_name }
      .map { |mapping| mapping.ebs.volume_id }
  end

  private

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
