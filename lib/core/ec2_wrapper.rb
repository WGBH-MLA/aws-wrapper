require_relative 'base_wrapper'

module Ec2Wrapper
  include BaseWrapper
  
  private
  
  def ec2_client
    @ec2_client ||= Aws::EC2::Client.new(client_config)
  end
  
  public
  
  
  def create_and_attach_volume(instance_id, device)
    volume_id = ec2_client.create_volume({
      # dry_run: true,
      size: 1,
      #snapshot_id: "String",
      availability_zone: AVAILABILITY_ZONE, # required
      volume_type: "standard", # accepts standard, io1, gp2
      #iops: 1,
      #encrypted: true,
      #kms_key_id: "String",
    }).volume_id
    1.upto(WAIT_ATTEMPTS) do |try|
      volume = ec2_client.describe_volumes(volume_ids: [volume_id]).volumes.select do |vol|
        vol.volume_id = volume_id
      end.first
      break if volume && volume.state == 'available'
      fail('Giving up') if try >= WAIT_ATTEMPTS
      LOGGER.info("try #{try}: Volume #{volume_id} not yet available")
      sleep(WAIT_INTERVAL)
    end
    ec2_client.attach_volume({
      # dry_run: true,
      volume_id: volume_id, # required
      instance_id: instance_id, # required
      device: device, # required: /dev/sdb thru /dev/sdp
    })
    ec2_client.modify_instance_attribute(
      instance_id: instance_id, # required
      attribute: 'blockDeviceMapping',
      block_device_mappings: [
        {
          device_name: device,
          ebs: {
            volume_id: volume_id,
            delete_on_termination: true,
          }
        }
      ]
    )
  end
  
  def key_path(name)
    "#{Dir.home}/.ssh/#{name}.pem"
  end
  
  def create_key(name, save_key = true)
    key_path = key_path(name)
    fail("PK already exists: #{key_path}") if File.exists?(key_path)
    key = ec2_client.create_key_pair({
      key_name: name  
    })
    if save_key
      File.write(key_path, key.key_material)
      LOGGER.info("Created key pair and stored private key at #{key_path}. Fingerprint: #{key.key_fingerprint}")
    end
    key
  end
  
  def delete_key(name)
    File.delete(key_path(name))
    ec2_client.delete_key_pair({
      key_name: name  
    })
  end
  
  def start_instances(n, key_name, instance_type = 't1.micro')
    response_run_instances = ec2_client.run_instances({
      dry_run: false,
      image_id: "ami-cf1066aa", # PV EBS-Backed 64-bit / US East
      min_count: n, # required
      max_count: n, # required
      key_name: key_name,
      instance_type: instance_type,
      monitoring: {
        enabled: false, # required
      },
      disable_api_termination: false,
      instance_initiated_shutdown_behavior: "terminate", # accepts stop, terminate
    })
    instances = response_run_instances.instances

    ec2_client.wait_until(:instance_running, instance_ids: instances.map(&:instance_id)) do |w|
      config_wait(w)
    end
    
    return instances
  end
  
  def terminate_instances(key_name)
    instance_ids = ec2_client.describe_instances({
      filters: [{
        name: 'key-name',
        values: [key_name],
      }]
    }).reservations.map { |res| res.instances.map { |inst| inst.instance_id } }.flatten
    ec2_client.terminate_instances({
      instance_ids: instance_ids
    })
  end
  
#  def lookup_eip(eip_ip)
#    response = ec2_client.describe_addresses({
#      dry_run: false,
#      public_ips: [eip_ip],
##      filters: [
##        {
##          name: "String",
##          values: ["String"],
##        },
##      ],
##      allocation_ids: ["String"],
#    })
#    fail("Expected exactly one match, not #{response.addresses.count}") unless response.addresses.count == 1
#    response.addresses[0] # Returns an Address, which has .instance_id
#  end
  
#  def allocate_eip(instance)
#    response_allocate_address = ec2_client.allocate_address({
#      dry_run: false,
#      domain: "standard", # accepts vpc, standard
#    })
#    public_ip = response_allocate_address.public_ip
#    assign_eip(public_ip, instance)
#    return public_ip
#  end
  
#  def assign_eip(public_ip, instance)
#    instance_id = instance.instance_id
#    ec2_client.associate_address({
#      dry_run: false,
#      instance_id: instance_id,
#      public_ip: public_ip, # required for EC2-Classic
#      # allocation_id: response_allocate_address.allocation_id, # required for EC2-VPC
#      # allow_reassociation: true, # allowReassociation parameter is only supported when mapping to a VPC
#      # TODO: Isn't the whole point of EIP that it can be reassociated?
#    })
#    LOGGER.info("EIP #{public_ip} -> EC2 #{instance_id}")
#  end
  
#  def lookup_instance(instance_id)
#    response_describe_instances = ec2_client.describe_instances({
#      dry_run: false,
#      instance_ids: [instance_id]
#    })
#    response_describe_instances.reservations[0].instances[0]
#  end
  
#  def lookup_ip(ip)
#    response_describe_instances = ec2_client.describe_instances({
#      dry_run: false
#    })
#    instances = response_describe_instances.reservations.map {|reservation|
#      reservation.instances
#    }.flatten
#    matches = instances.select{|instance| instance.public_ip_address == ip}
#    fail("Expected exactly one instance with IP #{ip}, not #{matches.count}") unless matches.count == 1
#    matches[0]
#  end
  
#  def stop_instances(instances)
#    # TODO: disassociate_address?
#    # TODO: release_address
#    instance_ids = instances.map(&:instance_id)
#  
#    response_stop_instances = ec2_client.stop_instances({
#      dry_run: false,
#      instance_ids: instance_ids,
#      force: true,
#    })
#
#    LOGGER.info("Requested EC2 instance termination: #{response_stop_instances.inspect}")
#
#    ec2_client.wait_until(:instance_terminated, instance_ids: instance_ids) do |w|
#      config_wait(w)
#    end
#  end
  
  private
  
  def config_wait(w)
    w.interval = WAIT_INTERVAL
    w.max_attempts = WAIT_ATTEMPTS
    w.before_wait do |n, last_response|
      # TODO: If this is only for EC2s, it should be moved there.
      status = last_response.data.reservations.map { |r| 
        r.instances.map { |i| 
          "#{i.instance_id}: #{i.state.name}"
        }
      }.flatten
      LOGGER.info("try #{n}: EC2 instances not ready yet. #{status}")
    end
  end
  
end
