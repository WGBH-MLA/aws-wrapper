require_relative 'base_wrapper'

module Ec2Wrapper
  include BaseWrapper
  
  def initialize
    super
    @ec2_client = Aws::EC2::Client.new(CLIENT_CONFIG)
  end
  
  def start_instances(n)
    response_run_instances = @ec2_client.run_instances({
      dry_run: false,
      image_id: "ami-cf1066aa", # PV EBS-Backed 64-bit / US East
      min_count: n, # required
      max_count: n, # required
      key_name: "aapb", # TODO: Command-line parameter? Script to create in the first place?
      instance_type: "t1.micro",
      monitoring: {
        enabled: false, # required
      },
      disable_api_termination: false,
      instance_initiated_shutdown_behavior: "terminate", # accepts stop, terminate
    })
    instances = response_run_instances.instances

    LOGGER.info("Requested EC2 instances: #{instances.map(&:instance_id)}")

    @ec2_client.wait_until(:instance_running, instance_ids: instances.map(&:instance_id)) do |w|
      config_wait(w)
    end
    
    return instances
  end
  
  def allocate_eip(instance)
    response_allocate_address = @ec2_client.allocate_address({
      dry_run: false,
      domain: "standard", # accepts vpc, standard
    })
    public_ip = response_allocate_address.public_ip
    assign_eip(public_ip, instance)
    return public_ip
  end
  
  def assign_eip(public_ip, instance)
    instance_id = instance.instance_id
    @ec2_client.associate_address({
      dry_run: false,
      instance_id: instance_id,
      public_ip: public_ip, # required for EC2-Classic
      # allocation_id: response_allocate_address.allocation_id, # required for EC2-VPC
      # allow_reassociation: true, # allowReassociation parameter is only supported when mapping to a VPC
      # TODO: Isn't the whole point of EIP that it can be reassociated?
    })
    LOGGER.info("EIP #{public_ip} -> EC2 #{instance_id}")
  end
  
  def lookup_instance(instance_id)
    response_describe_instances = @ec2_client.describe_instances({
      dry_run: false,
      instance_ids: [instance_id],
    })
    response_describe_instances.reservations[0].instances[0]
  end
  
  def stop_instances(instances)
    # TODO: disassociate_address?
    # TODO: release_address
    instance_ids = instances.map(&:instance_id)
  
    response_stop_instances = @ec2_client.stop_instances({
      dry_run: false,
      instance_ids: instance_ids,
      force: true,
    })

    LOGGER.info("Requested EC2 instance termination: #{response_stop_instances.inspect}")

    @ec2_client.wait_until(:instance_terminated, instance_ids: instance_ids) do |w|
      config_wait(w)
    end
  end
  
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
      LOGGER.info("#{n}: Waiting... #{status}")
    end
  end
  
end
